//------------------------------------------------------------------------------
//  File:          BreadFinancialWebViewInterstitialTests.swift
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
import WebKit

@testable import BreadPartners

@Suite
@MainActor
struct BreadFinancialWebViewInterstitialTests {
    @Test
    func disclosureCaptureSessionRetainsWebViewAndRejectsDuplicates() throws {
        let interstitial = makeInterstitial(events: EventCapture())
        weak var retainedWebView: WKWebView?

        do {
            let webView = try #require(
                interstitial.makeDisclosureCaptureWebView(with: WKWebViewConfiguration())
            )
            retainedWebView = webView
            #expect(webView.navigationDelegate is DocumentContentReadyObserver)
        }

        #expect(retainedWebView != nil)
        #expect(interstitial.makeDisclosureCaptureWebView(with: WKWebViewConfiguration()) == nil)
    }

    @Test
    func unifiedCheckoutResultEmitsExistingCallbacksInOrder() throws {
        let events = EventCapture()
        let interstitial = makeInterstitial(events: events)
        let payload: [String: Any] = ["applicationId": "application-123"]

        interstitial.handleScriptMessageBody([
            "action": [
                "type": "RECEIVE_UNIFIED_CHECKOUT_APPLICATION_RESULT",
                "payload": payload,
            ]
        ])

        try #require(events.eventCount == 3)
        guard case let .webViewSuccess(successPayload) = events.events[0],
            case let .receiveUnifiedCheckoutApplicationResult(resultPayload) = events.events[1],
            case .popupClosed = events.events[2]
        else {
            Issue.record("Expected success, unified-checkout result, then popup-closed callbacks")
            return
        }
        #expect((successPayload as? [String: Any])?["applicationId"] as? String == "application-123")
        #expect((resultPayload as? [String: Any])?["applicationId"] as? String == "application-123")
    }

    @Test(
        arguments: zip(
            [
                "VIEW_PAGE", "CANCEL_APPLICATION", "SUBMIT_APPLICATION", "SUBMIT_PREQUAL_APPLICATION",
                "APPLICATION_COMPLETED",
            ],
            [
                ["screenName:product"],
                ["popupClosed"],
                ["screenName:submit-application"],
                ["submitPrequalApplication"],
                ["screenName:application-completed", "applicationCompleted", "popupClosed"],
            ]
        ))
    func simpleMessageEmitsExpectedCallbacks(type: String, expectedCallbacks: [String]) {
        let events = EventCapture()
        let interstitial = makeInterstitial(events: events)
        var action: [String: Any] = ["type": type]
        if type == "VIEW_PAGE" {
            action["payload"] = ["pageName": "product"]
        }

        interstitial.handleScriptMessageBody(["action": action])

        #expect(callbackKinds(events.events) == expectedCallbacks)
    }

    @Test(
        arguments: zip(
            [
                "RECEIVE_APPLICATION_RESULT",
                "RECEIVE_PRESCREEN_APPLICATION_RESULT",
                "UNIFIED_OFFERS_RECEIVED",
                "RECEIVE_PREQUAL_APPLICATION_RESULT",
                "RECEIVE_ACCOUNT_EXISTS",
            ],
            [
                ["webViewSuccess"],
                ["webViewSuccess"],
                ["webViewSuccess", "unifiedOffersReceived"],
                ["webViewSuccess", "receivePrequalApplicationResult"],
                ["receiveAccountExist"],
            ]
        ))
    func resultMessageEmitsExpectedCallbacks(type: String, expectedCallbacks: [String]) {
        let events = EventCapture()
        let interstitial = makeInterstitial(events: events)
        let payload: [String: Any] = ["applicationId": "application-123"]

        interstitial.handleScriptMessageBody(["action": ["type": type, "payload": payload]])

        #expect(callbackKinds(events.events) == expectedCallbacks)
    }

    @Test(
        arguments: zip(
            ["YES", "NO", "NOT_ME", "ABANDONED", "PRESCREEN_NO"],
            [false, true, true, false, false]
        ))
    func offerResponseEmitsExpectedEvent(response: String, shouldClose: Bool) throws {
        let events = EventCapture()
        let interstitial = makeInterstitial(events: events)

        interstitial.handleScriptMessageBody(["action": ["type": "OFFER_RESPONSE", "payload": response]])

        #expect(events.eventCount == (shouldClose ? 2 : 1))
        guard case let .offerResponse(offerResponse) = events.first else {
            Issue.record("Expected an offer-response callback")
            return
        }
        #expect(offerResponse.rawValue == response)

        if shouldClose {
            guard case .popupClosed? = events.events.last else {
                Issue.record("Expected a close callback for this offer response")
                return
            }
        }
    }

    @Test
    func restartMessagesPreserveListenerAndNavigationState() {
        let events = EventCapture()
        let interstitial = makeInterstitial(events: events)
        let restartListener = AppRestartListenerSpy()
        interstitial.appRestartListener = restartListener

        interstitial.handleScriptMessageBody(["action": ["type": "LOG_OUT_OR_RESTART"]])
        interstitial.handleScriptMessageBody([
            "action": ["type": "APP_RESTART", "payload": "https://example.test/restart"]
        ])

        #expect(interstitial.pendingLogOutOrRestart)
        #expect(restartListener.urls == ["https://example.test/restart"])
        #expect(events.eventCount == 0)
    }

    @Test
    func restartNavigationLeaveClearsStateAndLoadsRequestedURL() throws {
        let presenter = NavigationConfirmationPresenterSpy()
        let interstitial = makeInterstitial(events: EventCapture(), presenter: presenter)
        let requestURL = try #require(URL(string: "https://example.test/leave"))
        var policies: [WKNavigationActionPolicy] = []
        var loadedURLs: [URL] = []
        interstitial.pendingLogOutOrRestart = true

        interstitial.handleRestartNavigation(
            to: requestURL,
            load: { loadedURLs.append($0) },
            decisionHandler: { policies.append($0) }
        )

        #expect(policies == [.cancel])
        #expect(interstitial.pendingNavigationURL == requestURL)
        #expect(interstitial.pendingLogOutOrRestart)
        #expect(presenter.presentCount == 1)
        presenter.chooseLeave()

        #expect(interstitial.pendingNavigationURL == nil)
        #expect(!interstitial.pendingLogOutOrRestart)
        #expect(loadedURLs == [requestURL])
    }

    @Test
    func restartNavigationStayClearsStateWithoutLoading() throws {
        let presenter = NavigationConfirmationPresenterSpy()
        let interstitial = makeInterstitial(events: EventCapture(), presenter: presenter)
        let requestURL = try #require(URL(string: "https://example.test/stay"))
        var loadedURLs: [URL] = []
        interstitial.pendingLogOutOrRestart = true

        interstitial.handleRestartNavigation(
            to: requestURL,
            load: { loadedURLs.append($0) },
            decisionHandler: { _ in }
        )
        presenter.chooseStay()

        #expect(interstitial.pendingNavigationURL == nil)
        #expect(!interstitial.pendingLogOutOrRestart)
        #expect(loadedURLs.isEmpty)
    }

    @Test
    func restartNavigationWithoutPresenterContinuesAndClearsState() throws {
        let presenter = NavigationConfirmationPresenterSpy(isAvailable: false)
        let interstitial = makeInterstitial(events: EventCapture(), presenter: presenter)
        let requestURL = try #require(URL(string: "https://example.test/no-presenter"))
        var policies: [WKNavigationActionPolicy] = []
        var loadedURLs: [URL] = []
        interstitial.pendingLogOutOrRestart = true

        interstitial.handleRestartNavigation(
            to: requestURL,
            load: { loadedURLs.append($0) },
            decisionHandler: { policies.append($0) }
        )

        #expect(policies == [.cancel])
        #expect(presenter.presentCount == 1)
        #expect(interstitial.pendingNavigationURL == nil)
        #expect(!interstitial.pendingLogOutOrRestart)
        #expect(loadedURLs == [requestURL])
    }

    @Test
    func matchingPendingNavigationIsAllowedAndPreservesRestartFlag() throws {
        let presenter = NavigationConfirmationPresenterSpy()
        let interstitial = makeInterstitial(events: EventCapture(), presenter: presenter)
        let requestURL = try #require(URL(string: "https://example.test/confirmed"))
        var policies: [WKNavigationActionPolicy] = []
        var loadedURLs: [URL] = []
        interstitial.pendingNavigationURL = requestURL
        interstitial.pendingLogOutOrRestart = true

        interstitial.handleRestartNavigation(
            to: requestURL,
            load: { loadedURLs.append($0) },
            decisionHandler: { policies.append($0) }
        )

        #expect(policies == [.allow])
        #expect(interstitial.pendingNavigationURL == nil)
        #expect(interstitial.pendingLogOutOrRestart)
        #expect(presenter.presentCount == 0)
        #expect(loadedURLs.isEmpty)
    }

    @Test
    func malformedUnknownAndPayloadlessMessagesEmitNoEvents() {
        let events = EventCapture()
        let interstitial = makeInterstitial(events: events)

        interstitial.handleScriptMessageBody(NSNull())
        interstitial.handleScriptMessageBody(["action": "invalid"])
        interstitial.handleScriptMessageBody(["action": ["type": 42]])
        interstitial.handleScriptMessageBody(["action": ["type": "UNKNOWN_MESSAGE"]])
        interstitial.handleScriptMessageBody([
            "action": ["type": "RECEIVE_APPLICATION_RESULT"]
        ])
        interstitial.handleScriptMessageBody([
            "action": ["type": "VIEW_PAGE", "payload": ["wrongKey": "page"]]
        ])
        interstitial.handleScriptMessageBody([
            "action": ["type": "OFFER_RESPONSE", "payload": "UNKNOWN_RESPONSE"]
        ])
        interstitial.handleScriptMessageBody(["action": ["type": "OFFER_RESPONSE", "payload": 42]])
        interstitial.handleScriptMessageBody([
            "action": ["type": "RECEIVE_UNIFIED_CHECKOUT_APPLICATION_RESULT", "payload": "invalid"]
        ])
        interstitial.handleScriptMessageBody(["action": ["type": "AnchorTags", "payload": 42]])
        interstitial.handleScriptMessageBody(["action": ["type": "HEIGHT_CHANGED"]])

        #expect(events.eventCount == 0)
    }

    @Test
    func anchorTagPayloadBranchesAreNoOps() {
        let events = EventCapture()
        let logger = Logger()
        logger.setCallback(events.record)
        logger.setLogging(enabled: true)
        let interstitial = makeInterstitial(events: events, logger: logger)

        interstitial.handleScriptMessageBody([
            "action": ["type": "AnchorTags", "payload": ["<a href=\"https://example.test\">Link</a>"] as [String]]
        ])
        interstitial.handleScriptMessageBody([
            "action": ["type": "AnchorTags", "payload": "No anchors found"]
        ])

        #expect(events.eventCount == 0)
    }

    @Test
    func externalOpeningReceivesOnlyValidParsedURLs() {
        let events = EventCapture()
        var openedURLs: [URL] = []
        let interstitial = makeInterstitial(events: events) { openedURLs.append($0) }

        interstitial.handleScriptMessageBody([
            "action": ["type": "OPEN_EXTERNAL", "payload": "https://example.test/path"]
        ])
        interstitial.handleScriptMessageBody(["action": ["type": "OPEN_EXTERNAL", "payload": "http://["]])
        interstitial.handleScriptMessageBody(["action": ["type": "OPEN_EXTERNAL", "payload": 42]])

        #expect(openedURLs == [URL(string: "https://example.test/path")!])
        #expect(events.eventCount == 0)
    }

    @Test
    func loggingFollowsLoggerEnabledStateAndIncludesMessageDetails() {
        let loggedEvents = EventCapture()
        let logger = Logger()
        logger.setCallback(loggedEvents.record)
        logger.setLogging(enabled: true)
        let interstitial = makeInterstitial(events: EventCapture(), logger: logger)

        interstitial.handleScriptMessageBody([
            "action": ["type": "LOAD_ADOBE_TRACKING_ID", "payload": ["adobeTrackingId": "adobe-123"]]
        ])
        interstitial.handleScriptMessageBody([
            "action": ["type": "RECEIVE_APPLICATION_RESULT", "payload": ["applicationId": "application-123"]]
        ])
        interstitial.handleScriptMessageBody(["action": ["type": "APP_RESTART", "payload": 42]])
        interstitial.handleScriptMessageBody(["action": ["type": "UNKNOWN_MESSAGE"]])

        #expect(loggedEvents.messages.contains { $0.contains("AdobeTrackingID") })
        #expect(loggedEvents.messages.contains { $0.contains("application-123") })
        #expect(loggedEvents.messages.contains { $0.contains("Issue in restarting application") })
        #expect(loggedEvents.messages.contains { $0.contains("WebViewMessage") })

        let disabledLoggerEvents = EventCapture()
        let disabledLogger = Logger()
        disabledLogger.setCallback(disabledLoggerEvents.record)
        makeInterstitial(events: EventCapture(), logger: disabledLogger)
            .handleScriptMessageBody(["action": ["type": "UNKNOWN_MESSAGE"]])
        #expect(disabledLoggerEvents.messages.isEmpty)
    }

    private func makeInterstitial(
        events: EventCapture,
        logger: Logger = Logger(),
        openExternalURL: @escaping (URL) -> Void = { _ in },
        presenter: (any NavigationConfirmationPresenting)? = nil
    ) -> BreadFinancialWebViewInterstitial {
        BreadFinancialWebViewInterstitial(
            logger: logger,
            callback: events.record,
            openExternalURL: openExternalURL,
            navigationConfirmationPresenter: presenter
        )
    }

    private func callbackKinds(_ events: [BreadPartnerEvents]) -> [String] {
        events.map { event in
            switch event {
            case let .screenName(name): "screenName:\(name)"
            case .popupClosed: "popupClosed"
            case .submitPrequalApplication: "submitPrequalApplication"
            case .applicationCompleted: "applicationCompleted"
            case .webViewSuccess: "webViewSuccess"
            case .unifiedOffersReceived: "unifiedOffersReceived"
            case .receivePrequalApplicationResult: "receivePrequalApplicationResult"
            case .receiveAccountExist: "receiveAccountExist"
            default: "other"
            }
        }
    }
}

private final class AppRestartListenerSpy: AppRestartListener {
    private(set) var urls: [String] = []

    func onAppRestartClicked(url: String) {
        urls.append(url)
    }
}

@MainActor
private final class NavigationConfirmationPresenterSpy: NavigationConfirmationPresenting {
    private let isAvailable: Bool
    private(set) var presentCount = 0
    private var onLeave: (() -> Void)?
    private var onStay: (() -> Void)?

    init(isAvailable: Bool = true) {
        self.isAvailable = isAvailable
    }

    func presentNavigationConfirmation(
        onLeave: @escaping () -> Void,
        onStay: @escaping () -> Void
    ) -> Bool {
        presentCount += 1
        guard isAvailable else {
            return false
        }
        self.onLeave = onLeave
        self.onStay = onStay
        return true
    }

    func chooseLeave() {
        onLeave?()
    }

    func chooseStay() {
        onStay?()
    }
}
