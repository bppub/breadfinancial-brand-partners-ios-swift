import BreadPartnersCore
import Foundation
import Testing

@testable import BreadPartners

@Suite
@MainActor
struct RTPSCoordinatorTests {
    @Test
    func batchPrescreenFetchesMapsAndPresentsPlacement() async {
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
        uiCoordinator: RTPSUICoordinatorSpy
    ) -> RTPSCoordinator {
        RTPSCoordinator(
            environment: .stage,
            endpointProvider: LiveAPIEndpointProvider(environment: .stage),
            dependencies: RTPSDependencies(
                recaptcha: RecaptchaStub(),
                httpClient: HTTPClientSpy(outcomes: []),
                requestBuilder: RTPSRequestBuilder(),
                responseDecoder: ResponseDecoderStub(responses: [])
            ),
            placementService: placementService,
            makeUICoordinator: { uiCoordinator }
        )
    }

    private func input(
        callback: @escaping @Sendable (BreadPartnerEvents) -> Void = { _ in }
    ) -> RealTimePrescreenInput {
        RealTimePrescreenInput(
            merchantConfiguration: RTPSTestFixtures.MerchantConfigurationFixture.complete,
            placementsConfiguration: PlacementConfiguration(
                rtpsData: RTPSData(customerAcceptedOffer: true)
            ),
            integrationKey: "integration-key",
            brandConfiguration: nil,
            splitTextAndAction: false,
            openPlacementExperience: true,
            forSwiftUI: false,
            logger: Logger(),
            callback: callback
        )
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
