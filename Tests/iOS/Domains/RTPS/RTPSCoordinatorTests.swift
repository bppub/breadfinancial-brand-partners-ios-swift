import BreadPartnersCore
import Foundation
import Testing
import BreadPartnersCore

@testable import BreadPartners

@Suite
@MainActor
struct RTPSCoordinatorTests {
    @Test
    func makePlacementEmbeddedURLStringBuildsBPSURLForAcceptedOffer() throws {
        let coordinator = makeCoordinator(
            placementService: PlacementServiceSpy(result: .success(placementResponse)),
            uiCoordinator: RTPSUICoordinatorSpy(),
            endpointProvider: EndpointProviderStub()
        )

        let url = try #require(
            URL(
                string: coordinator.makePlacementEmbeddedURLString(
                    for: input(rtpsData: RTPSData(customerAcceptedOffer: true))
                )
            )
        )

        #expect(url.host == "bps.test")
        #expect(url.path == "/batch-prescreen/start")
    }

    @Test
    func makePlacementEmbeddedURLStringBuildsRTPSURLForUnacceptedOffer() throws {
        let coordinator = makeCoordinator(
            placementService: PlacementServiceSpy(result: .success(placementResponse)),
            uiCoordinator: RTPSUICoordinatorSpy(),
            endpointProvider: EndpointProviderStub()
        )

        let url = try #require(
            URL(
                string: coordinator.makePlacementEmbeddedURLString(
                    for: input(rtpsData: RTPSData(customerAcceptedOffer: false))
                )
            )
        )

        #expect(url.host == "rtps.test")
        #expect(url.path == "/prescreen/offer")
    }

    @Test
    func batchPrescreenFetchesMapsAndPresentsPlacement() async throws {
        let placementService = PlacementServiceSpy(result: .success(placementResponse))
        let uiCoordinator = RTPSUICoordinatorSpy()
        let coordinator = makeCoordinator(
            placementService: placementService,
            uiCoordinator: uiCoordinator
        )

        await coordinator.runFlow(input())

        #expect(placementService.callCount == 1)
        #expect(placementService.request?.brandId == "integration-key")
        #expect(placementService.url != nil)
        #expect(uiCoordinator.popupPlacementModel?.overlayType == "EMBEDDED_OVERLAY")
        #expect(uiCoordinator.popupPlacementModel?.location == "checkout")
        #expect(uiCoordinator.popupPlacementModel?.webViewUrl == "https://embedded.test")
    }

    @Test
    func approvedPrescreenBuildsRTPSWebURLAndPresentsPlacement() async throws {
        let placementService = PlacementServiceSpy(result: .success(placementResponse))
        let uiCoordinator = RTPSUICoordinatorSpy()
        let httpClient = HTTPClientSpy(outcomes: [.success(Data())])
        let response = RTPSResponse(
            returnCode: "01",
            prescreenId: 9001,
            firstName: "Grace",
            cardType: "storeCard"
        )
        let coordinator = makeCoordinator(
            placementService: placementService,
            uiCoordinator: uiCoordinator,
            httpClient: httpClient,
            responses: [.rtps(response)]
        )

        await coordinator.runFlow(
            input(rtpsData: RTPSData(locationType: .checkout))
        )

        #expect(await httpClient.requestCount == 1)
        #expect(placementService.callCount == 1)
        #expect(uiCoordinator.placementCallCount == 1)
    }

    @Test
    func noActionDoesNotPresentOrFetchPlacementsAndPublishesLogs() async {
        let placementService = PlacementServiceSpy(result: .success(placementResponse))
        let uiCoordinator = RTPSUICoordinatorSpy()
        let events = EventCapture()
        let logger = makeLogger(enabled: true, events: events)
        let coordinator = makeCoordinator(
            placementService: placementService,
            uiCoordinator: uiCoordinator,
            responses: [.rtps(RTPSTestFixtures.Response.neutral)]
        )

        await coordinator.runFlow(input(rtpsData: RTPSData(), logger: logger))

        #expect(placementService.callCount == 0)
        #expect(uiCoordinator.challengeCallCount == 0)
        #expect(uiCoordinator.failureCallCount == 0)
        #expect(uiCoordinator.placementCallCount == 0)
        #expect(events.messages.contains { $0.contains("No Cookies") })
        #expect(events.messages.contains { $0.contains("PreScreenID:Result: noHit") })
    }

    @Test
    func disabledLoggingDoesNotPublishLogCallbacks() async {
        let placementService = PlacementServiceSpy(result: .success(placementResponse))
        let uiCoordinator = RTPSUICoordinatorSpy()
        let events = EventCapture()
        let logger = makeLogger(enabled: false, events: events)
        let coordinator = makeCoordinator(
            placementService: placementService,
            uiCoordinator: uiCoordinator,
            responses: [.rtps(RTPSTestFixtures.Response.neutral)]
        )

        await coordinator.runFlow(input(rtpsData: RTPSData(), logger: logger))

        #expect(events.messages.isEmpty)
    }

    @Test
    func challengeForwardsContentAndRetriesWithCookie() async {
        let placementService = PlacementServiceSpy(result: .success(placementResponse))
        let uiCoordinator = RTPSUICoordinatorSpy()
        let httpClient = HTTPClientSpy(outcomes: [
            .failure(RTPSTestFixtures.Error.incapsula),
            .failure(NSError(domain: "Retry", code: 7)),
        ])
        let coordinator = makeCoordinator(
            placementService: placementService,
            uiCoordinator: uiCoordinator,
            httpClient: httpClient
        )

        await coordinator.runFlow(input(rtpsData: RTPSData()))

        #expect(uiCoordinator.challengeCallCount == 1)
        #expect(uiCoordinator.challengeHTMLContent == "<html>challenge</html>")
        #expect(uiCoordinator.challengeOriginalURL == "https://challenge.test")
        #expect(uiCoordinator.failureCallCount == 0)
        #expect(placementService.callCount == 0)

        uiCoordinator.completeChallenge(with: "incap_ses=test-cookie")

        let retryCompleted = await waitUntil {
            uiCoordinator.failureCallCount == 1
        }
        let requests = await httpClient.requests
        #expect(retryCompleted)
        #expect(requests.count == 2)
        #expect(requests[1].cookies == "incap_ses=test-cookie")
        guard case let .api(message) = uiCoordinator.lastFailure else {
            Issue.record("Expected retry failure to be forwarded")
            return
        }
        #expect(message == "The operation couldn’t be completed. (Retry error 7.)")
    }

    @Test
    func failureForwardsMissingFieldsToUICoordinator() async {
        let placementService = PlacementServiceSpy(result: .success(placementResponse))
        let uiCoordinator = RTPSUICoordinatorSpy()
        let coordinator = makeCoordinator(
            placementService: placementService,
            uiCoordinator: uiCoordinator
        )

        await coordinator.runFlow(
            input(
                merchantConfiguration: MerchantConfiguration(),
                rtpsData: RTPSData()
            )
        )

        #expect(uiCoordinator.failureCallCount == 1)
        guard case .missingRequiredFields = uiCoordinator.lastFailure else {
            Issue.record("Expected missing required fields failure")
            return
        }
        #expect(placementService.callCount == 0)
    }

    @Test
    func nilEnvironmentAndRTPSDataUseDefaults() async throws {
        let placementService = PlacementServiceSpy(result: .success(placementResponse))
        let uiCoordinator = RTPSUICoordinatorSpy()
        let httpClient = HTTPClientSpy(outcomes: [.success(Data())])
        let brandConfiguration = BrandConfiguration(
            uatRecaptchaSiteKey: "",
            stageRecaptchaSiteKey: "",
            productionRecaptchaSiteKey: ""
        )
        var merchantConfiguration = RTPSTestFixtures.MerchantConfigurationFixture.complete
        merchantConfiguration.env = nil
        let coordinator = makeCoordinator(
            placementService: placementService,
            uiCoordinator: uiCoordinator,
            httpClient: httpClient,
            responses: [.rtps(RTPSTestFixtures.Response.neutral)]
        )

        await coordinator.runFlow(
            input(
                merchantConfiguration: merchantConfiguration,
                rtpsData: nil,
                brandConfiguration: brandConfiguration
            )
        )

        #expect(await httpClient.requestCount == 1)
        #expect(placementService.callCount == 0)
        #expect(uiCoordinator.placementCallCount == 0)
    }

    @Test
    func liveInitializerUsesLiveDependenciesAndDefaultUI() async throws {
        let responseData = try JSONEncoder().encode(placementResponse)
        let httpClient = HTTPClientSpy(outcomes: [.success(responseData)])
        let events = EventCapture()
        let coordinator = RTPSCoordinator(
            environment: .stage,
            endpointProvider: LiveAPIEndpointProvider(environment: .stage),
            httpClient: httpClient
        )

        await coordinator.runFlow(input(callback: events.record))

        #expect(await httpClient.requestCount == 1)
        #expect(
            events.events.contains { event in
                if case .renderPopupView = event { return true }
                return false
            })
    }

    @Test
    func placementServiceFailurePublishesAPIError() async throws {
        let placementService = PlacementServiceSpy(
            result: .failure(
                NSError(
                    domain: "Placement", code: 7,
                    userInfo: [
                        NSLocalizedDescriptionKey: "network failure"
                    ]))
        )
        let uiCoordinator = RTPSUICoordinatorSpy()
        let events = EventCapture()
        let coordinator = makeCoordinator(
            placementService: placementService,
            uiCoordinator: uiCoordinator
        )

        await coordinator.runFlow(input(callback: events.record))

        let error = try #require(sdkError(from: events))
        #expect(error.code == 500)
        #expect(error.localizedDescription == Constants.apiError(message: "network failure"))
        #expect(uiCoordinator.popupPlacementModel == nil)
    }

    @Test
    func invalidPlacementResponsePublishesParsingError() async throws {
        let placementService = PlacementServiceSpy(
            result: .success(PlacementsResponse(placements: [], placementContent: nil))
        )
        let uiCoordinator = RTPSUICoordinatorSpy()
        let events = EventCapture()
        let coordinator = makeCoordinator(
            placementService: placementService,
            uiCoordinator: uiCoordinator
        )

        await coordinator.runFlow(input(callback: events.record))

        let error = try #require(sdkError(from: events))
        #expect(error.code == 500)
        #expect(error.localizedDescription == Constants.popupPlacementParsingError)
        #expect(uiCoordinator.popupPlacementModel == nil)
    }

    private func makeCoordinator(
        placementService: PlacementServiceSpy,
        uiCoordinator: RTPSUICoordinatorSpy,
        endpointProvider: any APIEndpointProviding = LiveAPIEndpointProvider(environment: .stage),
        httpClient: HTTPClientSpy = HTTPClientSpy(outcomes: [.success(Data())]),
        responses: [ResponseDecoderStub.Response] = []
    ) -> RTPSCoordinator {
        RTPSCoordinator(
            environment: .stage,
            endpointProvider: endpointProvider,
            dependencies: RTPSDependencies(
                recaptcha: RecaptchaStub(),
                httpClient: httpClient,
                requestBuilder: RTPSRequestBuilder(),
                responseDecoder: ResponseDecoderStub(responses: responses)
            ),
            placementService: placementService,
            makeUICoordinator: { uiCoordinator }
        )
    }

    private func input(
        merchantConfiguration: MerchantConfiguration = RTPSTestFixtures.MerchantConfigurationFixture.complete,
        rtpsData: RTPSData? = RTPSData(customerAcceptedOffer: true),
        brandConfiguration: BrandConfiguration? = nil,
        logger: Logger = Logger(),
        callback: @escaping @Sendable (BreadPartnerEvents) -> Void = { _ in }
    ) -> RealTimePrescreenInput {
        RealTimePrescreenInput(
            merchantConfiguration: merchantConfiguration,
            placementsConfiguration: PlacementConfiguration(rtpsData: rtpsData),
            integrationKey: "integration-key",
            brandConfiguration: brandConfiguration,
            splitTextAndAction: false,
            openPlacementExperience: true,
            forSwiftUI: false,
            logger: logger,
            callback: callback
        )
    }

    private func makeLogger(enabled: Bool, events: EventCapture) -> Logger {
        let logger = Logger()
        logger.setLogging(enabled: enabled)
        logger.setCallback(events.record)
        return logger
    }

    private func waitUntil(
        _ condition: @escaping @MainActor @Sendable () async -> Bool
    ) async -> Bool {
        for _ in 0..<1_000 {
            if await condition() { return true }
            await Task.yield()
        }
        return false
    }

    private var placementResponse: PlacementsResponse {
        PlacementsResponse(
            placements: [
                PlacementsModel(
                    id: "placement-id",
                    content: nil,
                    renderContext: RenderContextModel(
                        LOCATION: "checkout",
                        subchannel: nil,
                        RTPS_ID: nil,
                        PREQUAL_ID: nil,
                        PRICE: nil,
                        DATETIME: nil,
                        SDK_TID: nil,
                        BUYER_ID: nil,
                        channel: nil,
                        PREQUAL_CREDIT_LIMIT: nil,
                        ENV: nil,
                        ALLOW_CHECKOUT: nil,
                        embeddedUrl: "https://embedded.test"
                    )
                )
            ],
            placementContent: [
                PlacementContentModel(
                    id: "content-id",
                    contentType: "text/html",
                    contentData: ContentDataModel(
                        htmlContent: "<div class=\"epjs-css-overlay-title\">Title</div>"
                    ),
                    metadata: MetadataModel(
                        placementId: "placement-id",
                        productType: nil,
                        messageId: nil,
                        templateId: "overlay"
                    )
                )
            ]
        )
    }

    private func sdkError(from events: EventCapture) -> NSError? {
        guard case let .sdkError(error) = events.first else {
            Issue.record("Expected an SDK error event")
            return nil
        }
        return error as NSError
    }
}

private struct EndpointProviderStub: APIEndpointProviding {
    func url(for endpoint: APIEndpoint) -> URL {
        switch endpoint {
        case .bpsWebUrl:
            return URL(string: "https://bps.test/batch-prescreen/start")!
        case .rtpsWebUrl:
            return URL(string: "https://rtps.test/prescreen/offer")!
        default:
            return URL(string: "https://api.test/endpoint")!
        }
    }
}

private final class PlacementServiceSpy: PlacementServicing, @unchecked Sendable {
    private let result: Result<PlacementsResponse, NSError>
    private(set) var callCount = 0
    private(set) var request: PlacementRequest?
    private(set) var url: URL?

    init(result: Result<PlacementsResponse, NSError>) {
        self.result = result
    }

    func fetch(
        request: PlacementRequest,
        from url: URL
    ) async throws -> PlacementsResponse {
        callCount += 1
        self.request = request
        self.url = url
        return try result.get()
    }
}
