//------------------------------------------------------------------------------
//  File:          ChallengeControllerTests.swift
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
struct ChallengeControllerTests {
    @Test(arguments: [
        "https://comenity.net",
        "https://shop.breadfinancial.com",
        "https://accounts.hcaptcha.com",
        "https://gstatic.com",
        "https://newassets.hcaptcha.com",
        "https://brands.kmsmep.com",
    ])
    func allowsConfiguredHosts(urlString: String) throws {
        let url = try #require(URL(string: urlString))

        #expect(ChallengeController.navigationPolicy(for: url) == .allow)
    }

    @Test(arguments: [
        "https://example.com",
        "https://hcaptcha.example",
        "ftp://example.com",
    ])
    func cancelsUnconfiguredURLs(urlString: String) throws {
        let url = try #require(URL(string: urlString))

        #expect(ChallengeController.navigationPolicy(for: url) == .cancel)
    }

    @Test(arguments: ["data:text/html,<p>challenge</p>", "about:blank", "about:srcdoc"])
    func allowsDataAndAboutSchemes(urlString: String) throws {
        let url = try #require(URL(string: urlString))

        #expect(ChallengeController.navigationPolicy(for: url) == .allow)
    }

    @Test
    func cancelsWhenURLIsMissing() {
        #expect(ChallengeController.navigationPolicy(for: nil) == .cancel)
    }

    @Test
    func closeButtonPublishesPopupClosed() throws {
        var receivedEvent: BreadPartnerEvents?
        let challengeController = ChallengeController(
            htmlContent: "<html></html>",
            originalURL: "https://challenge.test",
            callback: { receivedEvent = $0 },
            onComplete: { _ in },
            logger: Logger()
        )
        challengeController.loadViewIfNeeded()

        guard let closeButton = challengeController.view.subviews.compactMap({ $0 as? UIButton }).first else {
            Issue.record("Expected ChallengeController to contain a close button")
            return
        }

        let closeButtonActions = closeButton.actions(
            forTarget: challengeController,
            forControlEvent: .touchUpInside
        )
        let closeButtonSelector = NSStringFromSelector(#selector(ChallengeController.closeButtonTapped))
        #expect(closeButtonActions?.contains(closeButtonSelector) == true)
        challengeController.closeButtonTapped()

        guard case .popupClosed? = receivedEvent else {
            Issue.record("Expected the close button to publish popupClosed")
            return
        }
    }

    @Test
    func forwardsCompleteCookieHeaderFromCookieStore() async throws {
        let completions = AsyncStream<String>.makeStream()
        let challengeController = ChallengeController(
            htmlContent: "<html></html>",
            originalURL: "https://challenge.test",
            onComplete: { completions.continuation.yield($0) },
            logger: Logger()
        )

        challengeController.loadViewIfNeeded()
        guard let webView = challengeController.view.subviews.compactMap({ $0 as? WKWebView }).first else {
            Issue.record("Expected ChallengeController to contain a WKWebView")
            return
        }

        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookie = try #require(
            HTTPCookie(properties: [
                .domain: "challenge.test",
                .path: "/",
                .name: "incap_ses_step21",
                .value: "cookie-value",
            ])
        )
        await cookieStore.setCookie(cookie)
        let cookies = await allCookies(in: cookieStore)
        let expectedHeader = cookies.map { "\($0.name)=\($0.value); " }.joined()

        challengeController.webView(webView, didStartProvisionalNavigation: nil)
        challengeController.webView(webView, didFinish: nil)
        challengeController.cookiesDidChange(in: cookieStore)

        var iterator = completions.stream.makeAsyncIterator()
        let forwardedHeader = await iterator.next()
        #expect(forwardedHeader == expectedHeader)
        #expect(forwardedHeader?.contains("incap_ses_step21=cookie-value") == true)
        challengeController.viewDidDisappear(false)
    }

    private func allCookies(in cookieStore: WKHTTPCookieStore) async -> [HTTPCookie] {
        await withCheckedContinuation { continuation in
            cookieStore.getAllCookies { cookies in
                continuation.resume(returning: cookies)
            }
        }
    }
}
