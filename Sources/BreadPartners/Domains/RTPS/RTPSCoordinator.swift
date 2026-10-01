import BreadPartnersCore
import Foundation

final class RTPSCoordinator: RealTimePrescreenCoordinating, @unchecked Sendable {
    let environment: BreadPartnersEnvironment
    let endpointProvider: any APIEndpointProviding
    private let rtpsDependencies: RTPSDependencies
    private let placementService: any PlacementServicing
    private let popupModelMapper = RTPSPopupModelMapper()
    private let makeUICoordinator: @MainActor @Sendable () -> any RTPSUICoordinating

    init(
        environment: BreadPartnersEnvironment,
        endpointProvider: any APIEndpointProviding,
        placementService: any PlacementServicing,
        makeUICoordinator: @escaping @MainActor @Sendable () -> any RTPSUICoordinating = {
            RTPSUICoordinator.live
        }
    ) {
        self.environment = environment
        self.endpointProvider = endpointProvider
        self.rtpsDependencies = RTPSDependencies(
            recaptcha: LiveRecaptchaProvider(),
            requestBuilder: RTPSRequestBuilder(),
            responseDecoder: LiveRTPSResponseDecoder()
        )
        self.placementService = placementService
        self.makeUICoordinator = makeUICoordinator
    }

    init(
        environment: BreadPartnersEnvironment,
        endpointProvider: any APIEndpointProviding,
        dependencies: RTPSDependencies,
        placementService: any PlacementServicing,
        makeUICoordinator: @escaping @MainActor @Sendable () -> any RTPSUICoordinating
    ) {
        self.environment = environment
        self.endpointProvider = endpointProvider
        self.rtpsDependencies = dependencies
        self.placementService = placementService
        self.makeUICoordinator = makeUICoordinator
    }

    func runFlow(_ input: RealTimePrescreenInput) async {
        await executeRTPS(input, cookies: nil)
    }

    private func executeRTPS(
        _ input: RealTimePrescreenInput,
        cookies: String?
    ) async {
        let uiCoordinator = await makeUICoordinator()
        let siteKey = input.brandConfiguration?.recaptchaSiteKey(
            for: input.merchantConfiguration.env ?? .prod
        )

        let outcome = await RTPSService(dependencies: rtpsDependencies).execute(
            RTPSServiceInput(
                httpClient: input.httpClient,
                merchantConfiguration: input.merchantConfiguration,
                rtpsData: input.placementsConfiguration.rtpsData ?? RTPSData(),
                integrationKey: input.integrationKey,
                siteKey: siteKey ?? "",
                prescreenURL: endpointProvider.url(for: .prescreen),
                virtualLookupURL: endpointProvider.url(for: .virtualLookup),
                cookies: cookies,
                isLoggingEnabled: input.logger.isLoggingEnabled,
                log: { input.logger.printLog($0) }
            )
        )

        switch outcome {
        case .noAction:
            return

        case .skipToPlacements:
            await fetchAndPresentPlacements(
                for: input,
                uiCoordinator: uiCoordinator,
            )

        case let .proceedToPlacements(response):
            let updatedInput = input.withResponseUpdates(response)

            await fetchAndPresentPlacements(
                for: updatedInput,
                uiCoordinator: uiCoordinator
            )

        case let .challenge(htmlContent, originalURL):
            await uiCoordinator.presentChallenge(
                htmlContent: htmlContent,
                originalURL: originalURL,
                callback: input.callback,
                logger: input.logger,
                onComplete: { [self] cookie in
                    Task {
                        await executeRTPS(
                            input,
                            cookies: cookie,
                        )
                    }
                }
            )

        case let .failure(failure):
            await uiCoordinator.presentFailure(failure, callback: input.callback)
        }
    }

    private func fetchAndPresentPlacements(
        for input: RealTimePrescreenInput,
        uiCoordinator: any RTPSUICoordinating,
    ) async {
        do {
            let response = try await placementService.fetch(
                request: PlacementRequest(
                    placements: [
                        PlacementRequestBody(
                            context: ContextRequestBody(
                                ENV: input.merchantConfiguration.env?.rawValue,
                                LOCATION: "RTPS-Approval",
                                embeddedUrl: makePlacementEmbeddedURLString(for: input)
                            )
                        )
                    ],
                    brandId: input.integrationKey
                ),
                from: endpointProvider.url(for: .generatePlacements),
                httpClient: input.httpClient
            )
            let popupPlacementModel = try await popupModelMapper.map(response)

            await uiCoordinator.presentPlacement(
                popupPlacementModel,
                merchantConfiguration: input.merchantConfiguration,
                placementsConfiguration: input.placementsConfiguration,
                integrationKey: input.integrationKey,
                logger: input.logger,
                callback: input.callback
            )
        } catch is RTPSPopupModelMapperError {
            input.callback(
                .sdkError(
                    error: NSError(
                        domain: "",
                        code: 500,
                        userInfo: [
                            NSLocalizedDescriptionKey: Constants.popupPlacementParsingError
                        ]
                    )
                )
            )
        } catch {
            input.callback(
                .sdkError(
                    error: NSError(
                        domain: "",
                        code: 500,
                        userInfo: [
                            NSLocalizedDescriptionKey: Constants.apiError(
                                message: error.localizedDescription
                            )
                        ]
                    )
                )
            )
        }
    }

    func makePlacementEmbeddedURLString(for input: RealTimePrescreenInput) -> String {
        let placementsConfiguration = input.placementsConfiguration
        let rtpsData = placementsConfiguration.rtpsData

        if rtpsData?.customerAcceptedOffer == true {
            return WebURLBuilder.buildBPSWebURL(
                endpointURL: endpointProvider.url(for: .bpsWebUrl),
                integrationKey: input.integrationKey,
                rtpsData: rtpsData,
                placementData: placementsConfiguration.placementData,
                merchantConfiguration: input.merchantConfiguration
            ).absoluteString
        }

        return WebURLBuilder.buildRTPSWebURL(
            endpointURL: endpointProvider.url(for: .rtpsWebUrl(type: "offer")),
            integrationKey: input.integrationKey,
            rtpsData: rtpsData,
            merchantConfiguration: input.merchantConfiguration
        ).absoluteString
    }
}
