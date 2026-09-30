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
        httpClient: any HTTPClient,
        makeUICoordinator: @escaping @MainActor @Sendable () -> any RTPSUICoordinating = {
            RTPSUICoordinator.live
        }
    ) {
        self.environment = environment
        self.endpointProvider = endpointProvider
        self.rtpsDependencies = RTPSDependencies(
            recaptcha: LiveRecaptchaProvider(),
            httpClient: httpClient,
            requestBuilder: RTPSRequestBuilder(),
            responseDecoder: LiveRTPSResponseDecoder()
        )
        self.placementService = LivePlacementService(httpClient: httpClient)
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
        let siteKey = input.brandConfiguration?.config.getRecaptchaKey(
            for: input.merchantConfiguration.env ?? .prod
        )

        let outcome = await RTPSService(dependencies: rtpsDependencies).execute(
            RTPSServiceInput(
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
            let webURL: URL?
            if input.placementsConfiguration.rtpsData?.customerAcceptedOffer == true {
                webURL = WebURLBuilder.buildBPSWebURL(
                    environment: environment,
                    integrationKey: input.integrationKey,
                    rtpsData: input.placementsConfiguration.rtpsData,
                    placementData: input.placementsConfiguration.placementData,
                    merchantConfiguration: input.merchantConfiguration
                )
            } else {
                webURL = WebURLBuilder.buildRTPSWebURL(
                    environment: environment,
                    integrationKey: input.integrationKey,
                    rtpsData: input.placementsConfiguration.rtpsData,
                    merchantConfiguration: input.merchantConfiguration
                )
            }

            let response = try await placementService.fetch(
                request: PlacementRequest(
                    placements: [
                        PlacementRequestBody(
                            context: ContextRequestBody(
                                ENV: input.merchantConfiguration.env?.rawValue,
                                LOCATION: "RTPS-Approval",
                                embeddedUrl: webURL?.absoluteString
                            )
                        )
                    ],
                    brandId: input.integrationKey
                ),
                from: endpointProvider.url(for: .generatePlacements)
            )
            let popupPlacementModel = try await popupModelMapper.map(response)

            await uiCoordinator.presentPlacement(
                popupPlacementModel,
                merchantConfiguration: input.merchantConfiguration,
                placementsConfiguration: input.placementsConfiguration,
                integrationKey: input.integrationKey,
                brandConfiguration: input.brandConfiguration,
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
}
