import Foundation
import Testing
import UIKit

@testable import BreadPartners

@Suite
@MainActor
struct RTPSUICoordinatorTests {
    @Test
    func presentChallengeUsesFactoryAndPublishesController() {
        let controller = UIViewController()
        let factory = ChallengeControllerFactorySpy(controller: controller)
        let coordinator = RTPSUICoordinator(
            challengeFactory: factory,
            popupFactory: PopupFactorySpy()
        )
        let events = EventCapture()
        let logger = Logger()
        var completionValue: String?

        coordinator.presentChallenge(
            htmlContent: "challenge",
            originalURL: "https://challenge.test",
            callback: events.record,
            logger: logger,
            onComplete: { completionValue = $0 }
        )

        #expect(factory.htmlContent == "challenge")
        #expect(factory.originalURL == "https://challenge.test")
        #expect(factory.logger === logger)
        guard case let .renderPopupView(view) = events.first else {
            Issue.record("Expected a render popup event")
            return
        }
        #expect(view === controller)

        factory.callback?(.popupClosed)
        factory.onComplete?("challenge-result")
        #expect(events.eventCount == 2)
        #expect(completionValue == "challenge-result")
    }

    @Test
    func presentFailureMapsMissingRequiredFields() throws {
        let events = EventCapture()

        makeCoordinator().presentFailure(.missingRequiredFields, callback: events.record)

        let error = try #require(sdkError(from: events))
        #expect(error.code == 400)
        #expect(error.localizedDescription == Constants.prescreenRequiredFieldsError)
    }

    @Test
    func presentFailureMapsAPIMessage() throws {
        let events = EventCapture()

        makeCoordinator().presentFailure(.api(message: "network failure"), callback: events.record)

        let error = try #require(sdkError(from: events))
        #expect(error.code == 500)
        #expect(error.localizedDescription == Constants.apiError(message: "network failure"))
    }

    @Test
    func presentFailurePublishesUnderlyingError() throws {
        let events = EventCapture()
        let underlyingError = NSError(domain: "Test", code: 7)

        makeCoordinator().presentFailure(.underlying(underlyingError), callback: events.record)

        let error = try #require(sdkError(from: events))
        #expect(error === underlyingError)
    }

    @Test
    func presentPlacementResponseRejectsEmptyPlacements() async {
        let popupFactory = PopupFactorySpy()
        let coordinator = makeCoordinator(popupFactory: popupFactory)
        let events = EventCapture()

        await coordinator.presentPlacementResponse(
            emptyResponse,
            merchantConfiguration: RTPSTestFixtures.MerchantConfigurationFixture.complete,
            placementsConfiguration: RTPSTestFixtures.PlacementConfigurationFixture.rtps,
            integrationKey: "integration-key",
            brandConfiguration: nil,
            splitTextAndAction: false,
            openPlacementExperience: true,
            forSwiftUI: false,
            logger: Logger(),
            callback: events.record
        )

        #expect(popupFactory.callCount == 0)
        #expect(events.containsSDKError)
    }

    @Test
    func presentPlacementResponseRejectsNilPlacements() async {
        let popupFactory = PopupFactorySpy()
        let coordinator = makeCoordinator(popupFactory: popupFactory)
        let events = EventCapture()

        await coordinator.presentPlacementResponse(
            PlacementsResponse(placements: nil, placementContent: nil),
            merchantConfiguration: RTPSTestFixtures.MerchantConfigurationFixture.complete,
            placementsConfiguration: RTPSTestFixtures.PlacementConfigurationFixture.rtps,
            integrationKey: "integration-key",
            brandConfiguration: nil,
            splitTextAndAction: false,
            openPlacementExperience: false,
            forSwiftUI: false,
            logger: Logger(),
            callback: events.record
        )

        #expect(popupFactory.callCount == 0)
        #expect(events.containsSDKError)
    }

    @Test
    func presentPlacementResponseRejectsMissingOverlayContent() async {
        let popupFactory = PopupFactorySpy()
        let coordinator = makeCoordinator(popupFactory: popupFactory)
        let events = EventCapture()
        let response = PlacementsResponse(
            placements: [placement],
            placementContent: nil
        )

        await coordinator.presentPlacementResponse(
            response,
            merchantConfiguration: RTPSTestFixtures.MerchantConfigurationFixture.complete,
            placementsConfiguration: RTPSTestFixtures.PlacementConfigurationFixture.rtps,
            integrationKey: "integration-key",
            brandConfiguration: nil,
            splitTextAndAction: false,
            openPlacementExperience: false,
            forSwiftUI: true,
            logger: Logger(),
            callback: events.record
        )

        #expect(popupFactory.callCount == 0)
        #expect(events.containsSDKError)
    }

    @Test
    func presentPlacementResponseRejectsContentWithoutOverlayTemplate() async {
        let popupFactory = PopupFactorySpy()
        let coordinator = makeCoordinator(popupFactory: popupFactory)
        let events = EventCapture()
        let response = PlacementsResponse(
            placements: [placement],
            placementContent: [placementContent(templateId: "text")]
        )

        await coordinator.presentPlacementResponse(
            response,
            merchantConfiguration: RTPSTestFixtures.MerchantConfigurationFixture.complete,
            placementsConfiguration: RTPSTestFixtures.PlacementConfigurationFixture.rtps,
            integrationKey: "integration-key",
            brandConfiguration: nil,
            splitTextAndAction: false,
            openPlacementExperience: false,
            forSwiftUI: false,
            logger: Logger(),
            callback: events.record
        )

        #expect(popupFactory.callCount == 0)
        #expect(events.containsSDKError)
    }

    @Test
    func presentPlacementResponseUsesEmptyHTMLWhenContentDataIsMissing() async {
        let popupFactory = PopupFactorySpy()
        let coordinator = makeCoordinator(popupFactory: popupFactory)
        let events = EventCapture()
        let response = PlacementsResponse(
            placements: [placement],
            placementContent: [placementContent(contentData: nil)]
        )

        await coordinator.presentPlacementResponse(
            response,
            merchantConfiguration: RTPSTestFixtures.MerchantConfigurationFixture.complete,
            placementsConfiguration: RTPSTestFixtures.PlacementConfigurationFixture.rtps,
            integrationKey: "integration-key",
            brandConfiguration: nil,
            splitTextAndAction: false,
            openPlacementExperience: false,
            forSwiftUI: false,
            logger: Logger(),
            callback: events.record
        )

        #expect(popupFactory.callCount == 1)
        #expect(popupFactory.popupPlacementModel?.overlayTitle.string == "")
    }

    @Test
    func presentPlacementResponseDefaultsMissingRenderContext() async {
        let popupFactory = PopupFactorySpy()
        let coordinator = makeCoordinator(popupFactory: popupFactory)
        let events = EventCapture()
        let response = PlacementsResponse(
            placements: [PlacementsModel(id: "placement-id", content: nil, renderContext: nil)],
            placementContent: [placementContent()]
        )

        await coordinator.presentPlacementResponse(
            response,
            merchantConfiguration: RTPSTestFixtures.MerchantConfigurationFixture.complete,
            placementsConfiguration: RTPSTestFixtures.PlacementConfigurationFixture.rtps,
            integrationKey: "integration-key",
            brandConfiguration: nil,
            splitTextAndAction: false,
            openPlacementExperience: false,
            forSwiftUI: false,
            logger: Logger(),
            callback: events.record
        )

        #expect(popupFactory.popupPlacementModel?.location == nil)
        #expect(popupFactory.popupPlacementModel?.webViewUrl == "")
    }

    @Test
    func presentPlacementResponseParsesOverlayAndUsesPopupFactory() async throws {
        let popupFactory = PopupFactorySpy()
        let coordinator = makeCoordinator(popupFactory: popupFactory)
        let events = EventCapture()
        let placementsConfiguration = RTPSTestFixtures.PlacementConfigurationFixture.rtps
        let merchantConfiguration = RTPSTestFixtures.MerchantConfigurationFixture.complete
        let logger = Logger()
        let brandConfiguration = try JSONDecoder().decode(
            BrandConfigResponse.self,
            from: Data(#"{"config":{}}"#.utf8)
        )

        await coordinator.presentPlacementResponse(
            responseWithOverlay,
            merchantConfiguration: merchantConfiguration,
            placementsConfiguration: placementsConfiguration,
            integrationKey: "integration-key",
            brandConfiguration: brandConfiguration,
            splitTextAndAction: true,
            openPlacementExperience: false,
            forSwiftUI: true,
            logger: logger,
            callback: events.record
        )

        #expect(popupFactory.callCount == 1)
        #expect(popupFactory.integrationKey == "integration-key")
        #expect(popupFactory.merchantConfiguration?.storeNumber == merchantConfiguration.storeNumber)
        #expect(popupFactory.placementsConfiguration?.rtpsData != nil)
        #expect(popupFactory.popupPlacementModel?.overlayType == "EMBEDDED_OVERLAY")
        #expect(popupFactory.popupPlacementModel?.location == "checkout")
        #expect(popupFactory.popupPlacementModel?.webViewUrl == "https://embedded.test")
        #expect(popupFactory.brandConfiguration != nil)
        #expect(popupFactory.logger === logger)

        let publishedEvents = events.events
        #expect(publishedEvents.count == 2)
        guard case .textClicked = publishedEvents[0] else {
            Issue.record("Expected textClicked to be published first")
            return
        }
        guard case let .renderPopupView(view) = publishedEvents[1] else {
            Issue.record("Expected the popup controller to be published second")
            return
        }
        #expect(view === popupFactory.controller)

        popupFactory.callback?(.popupClosed)
        #expect(events.eventCount == 3)
    }

    private func makeCoordinator(
        popupFactory: PopupFactorySpy = PopupFactorySpy()
    ) -> RTPSUICoordinator {
        RTPSUICoordinator(
            challengeFactory: ChallengeControllerFactorySpy(controller: UIViewController()),
            popupFactory: popupFactory
        )
    }

    private func sdkError(from events: EventCapture) -> NSError? {
        guard case let .sdkError(error) = events.first else {
            Issue.record("Expected an SDK error event")
            return nil
        }
        return error as NSError
    }

    private var emptyResponse: PlacementsResponse {
        PlacementsResponse(placements: [], placementContent: nil)
    }

    private var placement: PlacementsModel {
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
    }

    private var responseWithOverlay: PlacementsResponse {
        PlacementsResponse(
            placements: [placement],
            placementContent: [placementContent()]
        )
    }

    private func placementContent(
        templateId: String = "overlay",
        contentData: ContentDataModel? = ContentDataModel(
            htmlContent: "<div class=\"epjs-css-overlay-title\">Title</div>"
        )
    ) -> PlacementContentModel {
        PlacementContentModel(
            id: "content-id",
            contentType: "text/html",
            contentData: contentData,
            metadata: MetadataModel(
                placementId: "placement-id",
                productType: nil,
                messageId: nil,
                templateId: templateId
            )
        )
    }
}

@MainActor
private final class ChallengeControllerFactorySpy: ChallengeControllerFactory, @unchecked Sendable {
    let controller: UIViewController
    private(set) var htmlContent: String?
    private(set) var originalURL: String?
    private(set) var logger: Logger?
    private(set) var callback: ((BreadPartnerEvents) -> Void)?
    private(set) var onComplete: ((String) -> Void)?

    init(controller: UIViewController) {
        self.controller = controller
    }

    func makeChallengeController(
        htmlContent: String,
        originalURL: String,
        callback: @escaping (BreadPartnerEvents) -> Void,
        onComplete: @escaping (String) -> Void,
        logger: Logger
    ) -> UIViewController {
        self.htmlContent = htmlContent
        self.originalURL = originalURL
        self.logger = logger
        self.callback = callback
        self.onComplete = onComplete
        return controller
    }
}

@MainActor
private final class PopupFactorySpy: PopupFactory, @unchecked Sendable {
    let controller = UIViewController()
    private(set) var callCount = 0
    private(set) var integrationKey: String?
    private(set) var merchantConfiguration: MerchantConfiguration?
    private(set) var placementsConfiguration: PlacementConfiguration?
    private(set) var popupPlacementModel: PopupPlacementModel?
    private(set) var brandConfiguration: BrandConfigResponse?
    private(set) var logger: Logger?
    private(set) var callback: ((BreadPartnerEvents) -> Void)?

    func makePopupController(
        integrationKey: String,
        merchantConfiguration: MerchantConfiguration,
        placementsConfiguration: PlacementConfiguration,
        popupPlacementModel: PopupPlacementModel,
        brandConfiguration: BrandConfigResponse?,
        logger: Logger,
        callback: @escaping (BreadPartnerEvents) -> Void
    ) -> UIViewController {
        callCount += 1
        self.integrationKey = integrationKey
        self.merchantConfiguration = merchantConfiguration
        self.placementsConfiguration = placementsConfiguration
        self.popupPlacementModel = popupPlacementModel
        self.brandConfiguration = brandConfiguration
        self.logger = logger
        self.callback = callback
        return controller
    }
}
