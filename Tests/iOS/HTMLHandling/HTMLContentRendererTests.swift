//------------------------------------------------------------------------------
//  File:          HTMLContentRendererTests.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Foundation
import Testing
import UIKit

@testable import BreadPartners

@Suite
@MainActor
struct HTMLContentRendererTests {
    private let textHTML = """
        <div class="ep-text-placement" data-action-type="SHOW_OVERLAY" data-action-content-id="popup">
            <div class="epjs-body">Offer <span class="epjs-body-action"><a>Apply</a></span></div>
        </div>
        """
    private let popupHTML = """
        <div data-overlay-metadata data-overlay-type="EMBEDDED_OVERLAY"></div>
        <iframe src="about:blank"></iframe>
        """

    @Test
    func missingTextContentDoesNotReportAnalyticsAndPreservesErrorCallback() async throws {
        let reporter = AnalyticsReporterSpy()
        let events = EventCapture()
        let renderer = HTMLContentRenderer(
            integrationKey: "brand", merchantConfiguration: MerchantConfiguration(),
            placementsConfiguration: PlacementConfiguration(), logger: Logger(),
            analyticsReporter: reporter,
            callback: events.record
        )

        await renderer.handleTextPlacement(responseModel: PlacementsResponse(placements: nil, placementContent: nil))

        #expect(await reporter.calls.isEmpty)
        #expect(events.eventCount == 1)
        guard case let .sdkError(error) = try #require(events.first) else {
            Issue.record("Expected the existing missing text content error")
            return
        }
        #expect((error as NSError).code == 500)
        #expect(error.localizedDescription == Constants.noTextPlacementError)
    }

    @Test(arguments: [false, true], [false, true])
    func successfulTextReportsOneViewAndPreservesRenderCallback(splitTextAndAction: Bool, forSwiftUI: Bool) async throws
    {
        let reporter = AnalyticsReporterSpy()
        let events = EventCapture()
        let renderer = makeRenderer(
            reporter: reporter, events: events,
            splitTextAndAction: splitTextAndAction, forSwiftUI: forSwiftUI
        )
        let response = makeResponse(textHTML: textHTML)

        await renderer.handleTextPlacement(responseModel: response)

        #expect(events.eventCount == 1)
        switch (splitTextAndAction, forSwiftUI, try #require(events.first)) {
        case (false, false, .renderTextViewWithLink): break
        case (false, true, .renderSwiftUITextViewWithLink): break
        case (true, false, .renderSeparateTextAndButton): break
        case (true, true, .renderSwiftUISeparateTextAndButton): break
        default: Issue.record("Expected the existing render callback for the selected mode")
        }
        let calls = await reporter.calls(atLeast: 1)
        #expect(calls.count == 1)
        #expect(calls.first?.event == .viewPlacement)
        #expect(calls.first?.placementResponse.placementContent?.first?.id == "text")
        #expect(events.eventCount == 1)
    }

    @Test
    func validPopupReportsOneClickAndPreservesOrderedCallbacks() async throws {
        let reporter = AnalyticsReporterSpy()
        let events = EventCapture()
        let renderer = makeRenderer(
            reporter: reporter, events: events)
        let response = makeResponse(textHTML: textHTML, popupHTML: popupHTML)
        let model = try #require(try await HTMLContentParser().extractTextPlacementModel(htmlContent: textHTML))

        await renderer.handlePopupPlacement(responseModel: response, textPlacementModel: model)

        try #require(events.eventCount == 2)
        guard case .textClicked = events.events[0],
            case let .renderPopupView(view) = events.events[1]
        else {
            Issue.record("Expected textClicked followed by renderPopupView")
            return
        }
        let popup = try #require(view as? PopupController)
        #expect(popup.overlayType == .embeddedOverlay)
        #expect(popup.integrationKey == "brand")
        #expect(popup.modalPresentationStyle == .overCurrentContext)
        #expect(popup.modalTransitionStyle == .crossDissolve)
        let calls = await reporter.calls(atLeast: 1)
        #expect(calls.count == 1)
        #expect(calls.first?.event == .clickPlacement)
        #expect(calls.first?.placementResponse.placementContent?.map(\.id) == ["text", "popup"])
        popup.callback(.popupClosed)
        guard case .popupClosed = try #require(events.events.last) else {
            Issue.record("Expected the popup callback to be forwarded unchanged")
            return
        }
    }

    @Test(arguments: [nil, "", "<div data-overlay-metadata data-overlay-type='UNKNOWN'></div>"] as [String?])
    func popupParsingOrOverlayFailureDoesNotReportAndPreservesError(popupHTML: String?) async throws {
        let reporter = AnalyticsReporterSpy()
        let events = EventCapture()
        let renderer = makeRenderer(reporter: reporter, events: events)
        let model = try #require(try await HTMLContentParser().extractTextPlacementModel(htmlContent: textHTML))

        await renderer.handlePopupPlacement(
            responseModel: makeResponse(textHTML: textHTML, popupHTML: popupHTML), textPlacementModel: model
        )

        #expect(await reporter.calls.isEmpty)
        #expect(events.eventCount == 1)
        guard case let .sdkError(error) = try #require(events.first) else {
            Issue.record("Expected the existing popup parsing or overlay error")
            return
        }
        #expect((error as NSError).code == 500)
        #expect(
            error.localizedDescription
                == (popupHTML == nil ? Constants.popupPlacementParsingError : Constants.missingPopupPlacementError))
    }

    @Test
    func noActionTapPreservesTextClickedWithoutClickAnalytics() async throws {
        let reporter = AnalyticsReporterSpy()
        let events = EventCapture()
        let renderer = makeRenderer(
            reporter: reporter, events: events,
            splitTextAndAction: true
        )
        let html = textHTML.replacingOccurrences(of: "SHOW_OVERLAY", with: "NO_ACTION")

        await renderer.handleTextPlacement(responseModel: makeResponse(textHTML: html))
        _ = await reporter.calls(atLeast: 1)
        await renderer.handleLinkInteraction(link: "Apply")

        try #require(events.eventCount == 2)
        guard case .renderSeparateTextAndButton = events.events[0], case .textClicked = events.events[1] else {
            Issue.record("Expected the render callback followed by textClicked")
            return
        }
        let calls = await reporter.calls
        #expect(calls.count == 1)
        #expect(calls.first?.event == .viewPlacement)
    }

    @Test
    func incompleteTextHTMLRetainsCurrentSuccessfulParseAndViewReporting() async throws {
        let reporter = AnalyticsReporterSpy()
        let events = EventCapture()
        let renderer = makeRenderer(
            reporter: reporter, events: events)

        await renderer.handleTextPlacement(responseModel: makeResponse(textHTML: ""))

        let calls = await reporter.calls(atLeast: 1)
        #expect(calls.count == 1)
        #expect(calls.first?.event == .viewPlacement)
        #expect(calls.first?.placementResponse.placementContent?.first?.contentData?.htmlContent == "")
        #expect(events.eventCount == 1)
        guard case .renderTextViewWithLink = try #require(events.first) else {
            Issue.record("Expected the current empty text render callback")
            return
        }
    }

    private func makeRenderer(
        reporter: any AnalyticsReporting,
        events: EventCapture,
        splitTextAndAction: Bool = false,
        forSwiftUI: Bool = false
    ) -> HTMLContentRenderer {
        return HTMLContentRenderer(
            integrationKey: "brand", merchantConfiguration: MerchantConfiguration(),
            placementsConfiguration: PlacementConfiguration().withDefaultPopupStylingIfMissing(),
            splitTextAndAction: splitTextAndAction, forSwiftUI: forSwiftUI,
            logger: Logger(),
            analyticsReporter: reporter,
            callback: events.record
        )
    }

    private func makeResponse(textHTML: String, popupHTML: String? = nil) -> PlacementsResponse {
        var content = [
            PlacementContentModel(
                id: "text", contentType: "text", contentData: ContentDataModel(htmlContent: textHTML), metadata: nil
            )
        ]
        if let popupHTML {
            content.append(
                PlacementContentModel(
                    id: "popup", contentType: "overlay", contentData: ContentDataModel(htmlContent: popupHTML),
                    metadata: nil
                ))
        }
        return PlacementsResponse(placements: nil, placementContent: content)
    }
}
