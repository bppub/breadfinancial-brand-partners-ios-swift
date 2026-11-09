//------------------------------------------------------------------------------
//  File:          PopupControllerTests.swift
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
struct PopupControllerTests {
    @Test
    func rendersProductPopupFromInput() async throws {
        let controller = PopupController(
            input: .product(
                style: PopUpStyling(),
                logoURL: "",
                title: NSAttributedString(string: "Your offer"),
                subtitle: NSAttributedString(string: "Offer details"),
                header: NSAttributedString(string: "Highlights"),
                sections: [PopupBodySection(tag: "h3", text: "Cash back")],
                disclosure: NSAttributedString(string: "Terms apply"),
                disclosureHTML: "",
                actionTitle: "Continue"
            ),
            logger: Logger(),
            callback: { _ in }
        )

        controller.loadViewIfNeeded()
        await controller.setupTask?.value

        let productView = try #require(controller.productView)
        #expect(productView.titleLabel.attributedText?.string == "Your offer")
        #expect(productView.subtitleLabel.attributedText?.string == "Offer details")
        #expect(productView.disclosureTextView.text == "Terms apply")
        #expect(productView.actionButton.title(for: .normal) == "Continue")
        #expect(productView.sectionStackView.arrangedSubviews.count == 1)
        #expect(controller.popupView.subviews.contains(productView))
        #expect(productView.bottomRowView.subviews.contains(productView.actionButton))
    }

    @Test
    func loadsPopupModelUsingCTAID() async {
        let fetcher = PopupModelFetcherSpy(
            content: PopupInput.Embedded(logoURL: "", webViewURL: "https://follow-up.test", showsCloseButton: true)
        )
        let controller = makeController(
            loadActionContent: { id in await fetcher.fetch(id) },
            callback: { _ in }
        )

        controller.loadViewIfNeeded()
        await controller.setupTask?.value

        #expect(await fetcher.requestedIDs == ["follow-up-fetch"])
        #expect(controller.webViewContent?.webViewURL == "https://follow-up.test")
    }

    @Test
    func reportsInvalidEmbeddedURL() async {
        let events = EventCapture()
        let controller = PopupController(
            input: .embedded(
                style: PopUpStyling(),
                logoURL: "",
                webViewURL: "http://[::1",
                showsCloseButton: true
            ),
            logger: Logger(),
            callback: events.record
        )

        controller.loadViewIfNeeded()
        await controller.setupTask?.value

        #expect(events.eventCount == 1)
        #expect(controller.loadingView == nil)
        guard case let .sdkError(error) = events.events[0] else {
            Issue.record("Expected an SDK error for an invalid embedded URL")
            return
        }
        #expect((error as NSError).code == 500)
    }

    @Test
    func missingFollowUpLoaderLeavesPopupModelUnchanged() async {
        let events = EventCapture()
        let controller = makeController(loadActionContent: nil, callback: events.record)
        controller.webViewContent = PopupInput.Embedded(
            logoURL: "", webViewURL: "https://existing.test", showsCloseButton: true
        )

        controller.loadViewIfNeeded()
        await controller.setupTask?.value

        #expect(controller.webViewContent?.webViewURL == "https://existing.test")
        #expect(events.eventCount == 0)
    }

    @Test
    func reportsMissingFollowUpLoaderWhenActionContentIsUnavailable() async {
        let events = EventCapture()
        let controller = makeController(loadActionContent: nil, callback: events.record)

        controller.loadViewIfNeeded()
        await controller.setupTask?.value

        #expect(events.eventCount == 1)
        guard case let .sdkError(error) = events.first else {
            Issue.record("Expected an SDK error when follow-up content cannot be loaded")
            return
        }
        #expect(error.localizedDescription == Constants.somethingWentWrong)
    }

    @Test
    func failedFetchReportsErrorAndLeavesMissingModelForActionFallback() async {
        let error = NSError(
            domain: "Transport",
            code: 503,
            userInfo: [NSLocalizedDescriptionKey: "service unavailable"]
        )
        let events = EventCapture()
        let controller = makeController(
            loadActionContent: { _ in throw error },
            callback: events.record
        )

        controller.loadViewIfNeeded()
        await controller.setupTask?.value

        #expect(events.eventCount == 1)
        guard case let .sdkError(fetchError) = events.first else {
            Issue.record("Expected the follow-up fetch error to be reported")
            return
        }
        #expect(fetchError.localizedDescription == Constants.apiError(message: error.localizedDescription))

        controller.actionButtonTapped()

        #expect(events.eventCount == 3)
        guard case .actionButtonTapped = events.events[1],
            case let .sdkError(actionError) = events.events[2]
        else {
            Issue.record("Expected action event followed by missing-model fallback")
            return
        }
        #expect(actionError.localizedDescription == Constants.somethingWentWrong)
    }

    @Test
    func invalidActionURLReportsErrorAndStopsLoader() async {
        let events = EventCapture()
        let controller = makeController(
            loadActionContent: { _ in
                PopupInput.Embedded(logoURL: "", webViewURL: "http://[::1", showsCloseButton: true)
            },
            callback: events.record
        )

        controller.loadViewIfNeeded()
        await controller.setupTask?.value
        controller.actionButtonTapped()

        #expect(events.eventCount == 2)
        guard case .actionButtonTapped = events.events[0],
            case let .sdkError(error) = events.events[1]
        else {
            Issue.record("Expected the action event followed by an invalid-URL SDK error")
            return
        }
        #expect(error.localizedDescription == Constants.unableToLoadWebURL(message: "http://[::1"))
        #expect(controller.productView?.isHidden == false)
        #expect(controller.loadingView?.isHidden == true)
        #expect(controller.embeddedView?.superview === controller.popupView)
        #expect(controller.embeddedView?.webView == nil)
    }

    @Test
    func forwardsNonClosingWebViewEvent() {
        let events = EventCapture()
        let controller = makeController(loadActionContent: nil, callback: events.record)

        controller.handleWebViewEvent(event: .webViewSuccess(result: "approved"))

        #expect(events.eventCount == 1)
        guard case let .webViewSuccess(result) = events.first else {
            Issue.record("Expected the WebView success event to be forwarded")
            return
        }
        #expect(result as? String == "approved")
    }

    @Test
    func closingWebViewEventPublishesPopupClosed() {
        let events = EventCapture()
        let controller = makeController(loadActionContent: nil, callback: events.record)

        controller.handleWebViewEvent(event: .popupClosed)

        #expect(events.eventCount == 1)
        guard case .popupClosed = events.first else {
            Issue.record("Expected the WebView close event to publish popupClosed")
            return
        }
    }

    private func makeController(
        loadActionContent: (@MainActor @Sendable (String?) async throws -> PopupInput.Embedded?)?,
        callback: @escaping @Sendable (BreadPartnerEvents) -> Void
    ) -> PopupController {
        PopupController(
            input: .product(
                style: PopUpStyling(),
                logoURL: "",
                title: NSAttributedString(string: "Offer"),
                subtitle: NSAttributedString(string: ""),
                header: NSAttributedString(string: ""),
                sections: [],
                disclosure: NSAttributedString(string: ""),
                disclosureHTML: "",
                actionTitle: "Continue",
                actionPlacementID: "follow-up-fetch",
                loadActionContent: loadActionContent
            ),
            logger: Logger(),
            callback: callback
        )
    }
}

private actor PopupModelFetcherSpy {
    private let content: PopupInput.Embedded?
    private(set) var requestedIDs: [String?] = []

    init(content: PopupInput.Embedded?) {
        self.content = content
    }

    func fetch(_ placementID: String?) -> PopupInput.Embedded? {
        requestedIDs.append(placementID)
        return content
    }
}
