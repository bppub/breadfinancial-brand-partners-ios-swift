//------------------------------------------------------------------------------
//  File:          PlacementPopupPresenterTests.swift
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

@Suite
@MainActor
struct PlacementPopupPresenterTests {
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
    func validPopupReportsOneClickAndPreservesOrderedCallbacks() async throws {
        let reporter = AnalyticsReporterSpy()
        let events = EventCapture()
        let presenter = makePresenter(reporter: reporter, events: events)
        let response = makeResponse(popupHTML: popupHTML)
        let model = try TextPlacementHTMLParser().extract(htmlContent: textHTML)

        await presenter.presentActionPopup(responseModel: response, textPlacementModel: model)

        try #require(events.eventCount == 2)
        guard case .textClicked = events.events[0],
            case let .renderPopupView(view) = events.events[1]
        else {
            Issue.record("Expected textClicked followed by renderPopupView")
            return
        }
        let popup = try #require(view as? PopupController)
        guard case .embedded = popup.input.content else {
            Issue.record("Expected an embedded popup input")
            return
        }
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
        let presenter = makePresenter(reporter: reporter, events: events)
        let model = try TextPlacementHTMLParser().extract(htmlContent: textHTML)

        await presenter.presentActionPopup(
            responseModel: makeResponse(popupHTML: popupHTML),
            textPlacementModel: model
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
                == (popupHTML == nil ? Constants.popupPlacementParsingError : Constants.missingPopupPlacementError)
        )
    }

    @Test
    func popupWithoutContentDataUsesEmptyHTMLAndPreservesMissingOverlayError() async throws {
        let reporter = AnalyticsReporterSpy()
        let events = EventCapture()
        let presenter = makePresenter(reporter: reporter, events: events)
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

        await presenter.presentActionPopup(responseModel: response, textPlacementModel: model)

        #expect(await reporter.calls.isEmpty)
        #expect(events.eventCount == 1)
        guard case let .sdkError(error) = try #require(events.first) else {
            Issue.record("Expected the missing popup overlay error")
            return
        }
        #expect((error as NSError).code == 500)
        #expect(error.localizedDescription == Constants.missingPopupPlacementError)
    }

    private func makePresenter(
        reporter: any AnalyticsReporting,
        events: EventCapture
    ) -> PlacementPopupPresenter {
        PlacementPopupPresenter(
            logger: Logger(),
            analyticsReporter: reporter,
            placementsConfiguration: PlacementConfiguration().withDefaultPopupStylingIfMissing(),
            callback: events.record,
            onLoadFollowUpPopupModel: { _ in nil }
        )
    }

    private func makeResponse(popupHTML: String?) -> PlacementsResponse {
        var content = [
            PlacementContentModel(
                id: "text",
                contentType: "text",
                contentData: ContentDataModel(htmlContent: textHTML),
                metadata: nil
            )
        ]
        if let popupHTML {
            content.append(
                PlacementContentModel(
                    id: "popup",
                    contentType: "overlay",
                    contentData: ContentDataModel(htmlContent: popupHTML),
                    metadata: nil
                )
            )
        }
        return PlacementsResponse(placements: nil, placementContent: content)
    }
}
