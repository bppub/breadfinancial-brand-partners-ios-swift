//------------------------------------------------------------------------------
//  File:          PlacementUICoordinatorTests.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import BreadPartnersCore
import BreadPartnersTestSupport
import Foundation
import Testing
import UIKit

@testable import BreadPartners

@Suite
@MainActor
struct PlacementUICoordinatorTests {
    @Test(arguments: [false, true], [false, true])
    func textPlacementUsesInputFlagsAndAnalytics(splitTextAndAction: Bool, forSwiftUI: Bool) async throws {
        let reporter = AnalyticsReporterSpy()
        let events = EventCapture()
        let input = makeInput(
            events: events, reporter: reporter,
            splitTextAndAction: splitTextAndAction, forSwiftUI: forSwiftUI
        )

        await makeCoordinator().presentPlacement(makeResponse(), input: input)

        #expect(events.eventCount == 1)
        switch (splitTextAndAction, forSwiftUI, try #require(events.first)) {
        case (false, false, .renderTextViewWithLink): break
        case (false, true, .renderSwiftUITextViewWithLink): break
        case (true, false, .renderSeparateTextAndButton): break
        case (true, true, .renderSwiftUISeparateTextAndButton): break
        default: Issue.record("Expected the render callback selected by the input flags")
        }
        let calls = await reporter.calls(atLeast: 1)
        #expect(calls.count == 1)
        #expect(calls.first?.event == .viewPlacement)
        #expect(calls.first?.placementResponse.placementContent?.first?.id == "text")
    }

    @Test
    func missingTextContentReportsRendererErrorWithoutAnalytics() async throws {
        let reporter = AnalyticsReporterSpy()
        let events = EventCapture()

        await makeCoordinator().presentPlacement(
            RTPSTestFixtures.Response.emptyPlacements,
            input: makeInput(events: events, reporter: reporter)
        )

        let error = try #require(sdkError(from: events))
        #expect(events.eventCount == 1)
        #expect(error.code == 500)
        #expect(error.localizedDescription == Constants.noTextPlacementError)
        #expect(await reporter.calls.isEmpty)
    }

    @Test
    func challengeUsesFactoryAndForwardsCompletion() {
        let challengeFactory = PlacementChallengeFactorySpy(controller: UIViewController())
        let coordinator = makeCoordinator(challengeFactory: challengeFactory)
        let events = EventCapture()
        var completedCookie: String?
        let logger = Logger()

        coordinator.presentChallenge(
            htmlContent: "<html>challenge</html>",
            originalURL: "https://challenge.test",
            callback: events.record,
            logger: logger,
            onComplete: { completedCookie = $0 }
        )

        #expect(challengeFactory.htmlContent == "<html>challenge</html>")
        #expect(challengeFactory.originalURL == "https://challenge.test")
        #expect(challengeFactory.logger === logger)
        guard case let .renderPopupView(view) = events.first else {
            Issue.record("Expected challenge controller to be rendered")
            return
        }
        #expect(view === challengeFactory.controller)

        challengeFactory.onComplete?("retry-cookie")
        #expect(completedCookie == "retry-cookie")
        challengeFactory.callback?(.popupClosed)
        #expect(events.eventCount == 2)
        guard case .popupClosed = events.events.last else {
            Issue.record("Expected the challenge callback to be forwarded")
            return
        }
    }

    @Test(arguments: ["Placement", NetworkChallengeConstants.domain])
    func failurePreservesChallengeErrorsAndMapsOtherErrors(domain: String) throws {
        let events = EventCapture()
        let failure = NSError(
            domain: domain,
            code: 42,
            userInfo: [NSLocalizedDescriptionKey: "request failed"]
        )

        makeCoordinator().presentFailure(failure, callback: events.record)

        let error = try #require(sdkError(from: events))
        #expect(events.eventCount == 1)
        if domain == NetworkChallengeConstants.domain {
            #expect(error === failure)
        } else {
            #expect(error.domain.isEmpty)
            #expect(error.code == 500)
            #expect(error.localizedDescription == Constants.apiError(message: "request failed"))
        }
    }

    @Test(arguments: ["EMBEDDED_OVERLAY", "UNKNOWN"])
    func popupSelectsOverlayContentAndPublishesOrderedEvents(overlayType: String) async throws {
        let reporter = AnalyticsReporterSpy()
        let events = EventCapture()
        let response = makeResponse(
            popupHTML: """
                <div data-overlay-metadata data-overlay-type="\(overlayType)"></div>
                <iframe src="about:blank"></iframe>
                """
        )

        await makeCoordinator().presentPlacement(
            response,
            input: makeInput(events: events, reporter: reporter, openPlacementExperience: true)
        )

        let publishedEvents = events.events
        try #require(publishedEvents.count == 2)
        guard case .textClicked = publishedEvents[0] else {
            Issue.record("Expected textClicked to be published first")
            return
        }
        guard case let .renderPopupView(view) = publishedEvents[1] else {
            Issue.record("Expected popup controller to be published second")
            return
        }
        let popup = try #require(view as? PopupController)
        #expect(popup.integrationKey == "integration-key")
        #expect(popup.overlayType == (overlayType == "EMBEDDED_OVERLAY" ? .embeddedOverlay : .singleProductOverlay))
        #expect(view.modalPresentationStyle == .overCurrentContext)
        #expect(view.modalTransitionStyle == .crossDissolve)
        #expect(await reporter.calls.isEmpty)

        popup.callback(.popupClosed)
        #expect(events.eventCount == 3)
        guard case .popupClosed = events.events.last else {
            Issue.record("Expected the popup callback to be forwarded")
            return
        }
    }

    @Test(arguments: [nil, "text"] as [String?])
    func popupWithoutOverlayMetadataReportsParsingError(templateId: String?) async throws {
        let reporter = AnalyticsReporterSpy()
        let events = EventCapture()

        await makeCoordinator().presentPlacement(
            makeResponse(popupHTML: "<div data-overlay-metadata></div>", templateId: templateId),
            input: makeInput(events: events, reporter: reporter, openPlacementExperience: true)
        )

        let error = try #require(sdkError(from: events))
        #expect(events.eventCount == 1)
        #expect(error.code == 500)
        #expect(error.localizedDescription == Constants.popupPlacementParsingError)
        #expect(await reporter.calls.isEmpty)
    }

    private func makeCoordinator(
        challengeFactory: PlacementChallengeFactorySpy = PlacementChallengeFactorySpy(
            controller: UIViewController()
        )
    ) -> PlacementUICoordinator {
        PlacementUICoordinator(challengeFactory: challengeFactory)
    }

    private func makeInput(
        events: EventCapture,
        reporter: any AnalyticsReporting,
        splitTextAndAction: Bool = false,
        forSwiftUI: Bool = false,
        openPlacementExperience: Bool = false
    ) -> PlacementCoordinatorInput {
        PlacementCoordinatorInput(
            httpClient: HTTPClientSpy(outcomes: []),
            analyticsReporter: reporter,
            integrationKey: "integration-key",
            merchantConfiguration: MerchantConfiguration(),
            placementsConfiguration: PlacementConfiguration().withDefaultPopupStylingIfMissing(),
            splitTextAndAction: splitTextAndAction,
            openPlacementExperience: openPlacementExperience,
            forSwiftUI: forSwiftUI,
            logger: Logger(),
            callback: events.record
        )
    }

    private func makeResponse(popupHTML: String? = nil, templateId: String? = "product-overlay") -> PlacementsResponse {
        var content = [
            PlacementContentModel(
                id: "text", contentType: "text",
                contentData: ContentDataModel(
                    htmlContent: """
                        <div class="ep-text-placement" data-action-type="SHOW_OVERLAY" data-action-content-id="popup">
                            <div class="epjs-body">Offer <span class="epjs-body-action"><a>Apply</a></span></div>
                        </div>
                        """
                ),
                metadata: nil
            )
        ]
        if let popupHTML {
            content.append(
                PlacementContentModel(
                    id: "popup", contentType: "overlay",
                    contentData: ContentDataModel(htmlContent: popupHTML),
                    metadata: MetadataModel(placementId: nil, productType: nil, messageId: nil, templateId: templateId)
                )
            )
        }
        return PlacementsResponse(placements: nil, placementContent: content)
    }

    private func sdkError(from events: EventCapture) -> NSError? {
        guard case let .sdkError(error) = events.first else {
            Issue.record("Expected an SDK error event")
            return nil
        }
        return error as NSError
    }
}

@MainActor
private final class PlacementChallengeFactorySpy: ChallengeControllerFactory, @unchecked Sendable {
    let controller: UIViewController
    private(set) var htmlContent: String?
    private(set) var originalURL: String?
    private(set) var logger: Logger?
    private(set) var onComplete: ((String) -> Void)?
    private(set) var callback: ((BreadPartnerEvents) -> Void)?

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
        self.onComplete = onComplete
        self.callback = callback
        return controller
    }
}
