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

import BreadPartnersTestSupport
import Foundation
import Testing
import UIKit

@testable import BreadPartners

@Suite(.serialized)
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
    private let noActionHTML = """
        <div class="ep-text-placement" data-action-type="NO_ACTION" data-action-content-id="popup">
            <div class="epjs-body">Pay <strong>today</strong> <span class="epjs-body-action"><a href="/apply"><em>Apply</em></a></span></div>
        </div>
        """

    @Test
    func missingTextContentDoesNotReportAnalyticsAndPreservesErrorCallback() async throws {
        let reporter = AnalyticsReporterSpy()
        let events = EventCapture()
        let renderer = HTMLContentRenderer(
            integrationKey: "brand", merchantConfiguration: MerchantConfiguration(),
            placementsConfiguration: PlacementConfiguration(), logger: Logger(),
            analyticsReporter: reporter,
            callback: events.record,
            onLoadFollowUpPopupModel: { _ in nil }
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

    @Test
    func textPlacementParserFailureReportsParsingErrorWithoutAnalytics() async throws {
        let reporter = AnalyticsReporterSpy()
        let events = EventCapture()
        let renderer = makeRenderer(
            reporter: reporter,
            events: events,
            textPlacementParser: { _ in
                throw NSError(domain: "TextPlacementParserTests", code: 1)
            }
        )

        await renderer.handleTextPlacement(responseModel: makeResponse(textHTML: textHTML))

        #expect(await reporter.calls.isEmpty)
        #expect(events.eventCount == 1)
        guard case let .sdkError(error) = try #require(events.first) else {
            Issue.record("Expected the existing text placement parsing error")
            return
        }
        #expect((error as NSError).code == 500)
        #expect(error.localizedDescription == Constants.textPlacementParsingError)
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
        case (false, false, .renderTextViewWithLink(let textView)):
            #expect(textView.attributedText.string == "Offer Apply")
        case (false, true, .renderSwiftUITextViewWithLink(let textView)):
            #expect(textView.text == "Offer Apply")
        case (true, false, .renderSeparateTextAndButton(let textView, let button)):
            #expect(textView.text.contains("Offer"))
            #expect(button.title(for: .normal) == "Apply")
            #expect(button.accessibilityIdentifier == "Apply")
        case (true, true, .renderSwiftUISeparateTextAndButton(let textView, let button)):
            #expect(textView.text.contains("Offer"))
            #expect(button.title == "Apply")
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
        let model = try TextPlacementHTMLParser().extract(htmlContent: textHTML)

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
        let model = try TextPlacementHTMLParser().extract(htmlContent: textHTML)

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
    func popupWithoutContentDataUsesEmptyHTMLAndPreservesMissingOverlayError() async throws {
        let reporter = AnalyticsReporterSpy()
        let events = EventCapture()
        let renderer = makeRenderer(reporter: reporter, events: events)
        let response = PlacementsResponse(
            placements: nil,
            placementContent: [
                PlacementContentModel(
                    id: "text",
                    contentType: "text",
                    contentData: ContentDataModel(htmlContent: textHTML),
                    metadata: nil
                ),
                PlacementContentModel(
                    id: "popup",
                    contentType: "overlay",
                    contentData: nil,
                    metadata: nil
                ),
            ]
        )
        let model = try TextPlacementHTMLParser().extract(htmlContent: textHTML)

        await renderer.handlePopupPlacement(responseModel: response, textPlacementModel: model)

        #expect(await reporter.calls.isEmpty)
        #expect(events.eventCount == 1)
        guard case let .sdkError(error) = try #require(events.first) else {
            Issue.record("Expected the missing popup overlay error")
            return
        }
        #expect((error as NSError).code == 500)
        #expect(error.localizedDescription == Constants.missingPopupPlacementError)
    }

    @Test(arguments: [false, true])
    func noActionSplitControlForwardsTapWithoutClickAnalytics(forSwiftUI: Bool) async throws {
        let reporter = AnalyticsReporterSpy()
        let events = EventCapture()
        let renderer = makeRenderer(
            reporter: reporter, events: events,
            splitTextAndAction: true, forSwiftUI: forSwiftUI
        )

        await renderer.handleTextPlacement(responseModel: makeResponse(textHTML: noActionHTML))
        let initialCalls = await waitForAnalyticsCalls(reporter, count: 1)
        #expect(initialCalls.map(\.event) == [.viewPlacement])

        if forSwiftUI {
            guard case let .renderSwiftUISeparateTextAndButton(_, button) = try #require(events.first) else {
                Issue.record("Expected the SwiftUI split text and button callback")
                return
            }
            button.action()
        } else {
            guard case let .renderSeparateTextAndButton(_, button) = try #require(events.first) else {
                Issue.record("Expected the UIKit split text and button callback")
                return
            }
            renderer.handleButtonTap(button)
        }

        #expect(await events.waitForEventCount(2))
        let recordedEvents = events.events
        guard recordedEvents.count > 1, case .textClicked = recordedEvents[1] else {
            Issue.record("Expected the split control tap to forward textClicked")
            return
        }
        let calls = await reporter.calls
        #expect(calls.count == 1)
        #expect(calls.first?.event == .viewPlacement)
    }

    @Test(arguments: [false, true])
    func noActionFormattedTextRemovesLinkStylingAndForwardsTap(forSwiftUI: Bool) async throws {
        let reporter = AnalyticsReporterSpy()
        let events = EventCapture()
        let renderer = makeRenderer(reporter: reporter, events: events, forSwiftUI: forSwiftUI)

        await renderer.handleTextPlacement(responseModel: makeResponse(textHTML: noActionHTML))
        let initialCalls = await waitForAnalyticsCalls(reporter, count: 1)
        #expect(initialCalls.map(\.event) == [.viewPlacement])

        let attributedText: NSAttributedString
        if forSwiftUI {
            let view: BreadPartnerLinkTextSwitUI
            guard case let .renderSwiftUITextViewWithLink(renderedView) = try #require(events.first) else {
                Issue.record("Expected a SwiftUI linked-text callback")
                return
            }
            view = renderedView
            attributedText = try #require(view.attributedText)
            view.onTap?()
        } else {
            let view: BreadPartnerLinkText
            guard case let .renderTextViewWithLink(renderedView) = try #require(events.first) else {
                Issue.record("Expected a UIKit linked-text callback")
                return
            }
            view = renderedView
            attributedText = try #require(view.attributedText)
            view.tapHandler?("")
        }

        #expect(attributedText.string.contains("Pay"))
        #expect(attributedText.string.contains("today"))
        #expect(attributedText.string.contains("Apply"))
        let boldRange = (attributedText.string as NSString).range(of: "today")
        let font = try #require(attributedText.attribute(.font, at: boldRange.location, effectiveRange: nil) as? UIFont)
        #expect(font.fontDescriptor.symbolicTraits.contains(.traitBold))
        assertNoLinkAttributes(in: attributedText)

        #expect(await events.waitForEventCount(2))
        let recordedEvents = events.events
        guard recordedEvents.count > 1, case .textClicked = recordedEvents[1] else {
            Issue.record("Expected the formatted text tap to forward textClicked")
            return
        }
        let calls = await reporter.calls
        #expect(calls.map(\.event) == [.viewPlacement])
    }

    @Test(arguments: [false, true])
    func noActionConversionFailureUsesPlainTextFallback(forSwiftUI: Bool) async throws {
        let reporter = AnalyticsReporterSpy()
        let events = EventCapture()
        let renderer = makeRenderer(
            reporter: reporter,
            events: events,
            forSwiftUI: forSwiftUI,
            htmlToAttributedString: { _ in nil }
        )

        await renderer.handleTextPlacement(responseModel: makeResponse(textHTML: noActionHTML))
        let calls = await waitForAnalyticsCalls(reporter, count: 1)
        #expect(calls.map(\.event) == [.viewPlacement])

        if forSwiftUI {
            guard case let .renderSwiftUITextViewWithLink(view) = try #require(events.first) else {
                Issue.record("Expected a SwiftUI text fallback callback")
                return
            }
            #expect(view.text.contains("Pay"))
            #expect(view.attributedText == nil)
        } else {
            guard case let .renderTextViewWithLink(view) = try #require(events.first) else {
                Issue.record("Expected a UIKit text fallback callback")
                return
            }
            #expect(view.attributedText.string.contains("Pay"))
            #expect(view.attributedText.attribute(.font, at: 0, effectiveRange: nil) == nil)
        }
        #expect(events.eventCount == 1)
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
        forSwiftUI: Bool = false,
        htmlToAttributedString: @escaping (String) -> NSAttributedString? = { $0.htmlToAttributedString() },
        textPlacementParser: @escaping (String) throws -> TextPlacementModel = { htmlContent in
            try TextPlacementHTMLParser().extract(htmlContent: htmlContent)
        }
    ) -> HTMLContentRenderer {
        return HTMLContentRenderer(
            integrationKey: "brand", merchantConfiguration: MerchantConfiguration(),
            placementsConfiguration: PlacementConfiguration().withDefaultPopupStylingIfMissing(),
            splitTextAndAction: splitTextAndAction, forSwiftUI: forSwiftUI,
            logger: Logger(),
            analyticsReporter: reporter,
            callback: events.record,
            onLoadFollowUpPopupModel: { _ in nil },
            htmlToAttributedString: htmlToAttributedString,
            textPlacementParser: textPlacementParser
        )
    }

    private func assertNoLinkAttributes(in attributedText: NSAttributedString) {
        let range = NSRange(location: 0, length: attributedText.length)
        var containsLink = false
        var containsUnderline = false
        attributedText.enumerateAttribute(.link, in: range) { value, _, _ in
            containsLink = containsLink || value != nil
        }
        attributedText.enumerateAttribute(.underlineStyle, in: range) { value, _, _ in
            containsUnderline = containsUnderline || value != nil
        }
        #expect(!containsLink)
        #expect(!containsUnderline)
    }

    private func waitForAnalyticsCalls(_ reporter: AnalyticsReporterSpy, count: Int) async -> [AnalyticsReporterSpy
        .Call]
    {
        for _ in 0..<100 {
            let calls = await reporter.calls
            if calls.count >= count {
                return calls
            }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        return await reporter.calls
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
