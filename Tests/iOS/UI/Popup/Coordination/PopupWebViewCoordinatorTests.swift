//------------------------------------------------------------------------------
//  File:          PopupWebViewCoordinatorTests.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Testing
import UIKit
import WebKit
@testable import BreadPartners

@Suite
@MainActor
struct PopupWebViewCoordinatorTests {
    @Test
    func installsConfiguredWebViewInEmbeddedView() throws {
        let coordinator = makeCoordinator()
        let embeddedView = PopupEmbeddedView()
        let url = try #require(URL(string: "about:blank"))

        let webView = coordinator.installWebView(with: url, in: embeddedView)

        #expect(embeddedView.webView === webView)
        #expect(webView.superview === embeddedView)
        #expect(webView.navigationDelegate != nil)
        #expect(webView.uiDelegate != nil)
    }

    @Test
    func restartReplacesTheInstalledWebView() throws {
        let coordinator = makeCoordinator()
        let embeddedView = PopupEmbeddedView()
        let initialURL = try #require(URL(string: "about:blank"))
        let initialWebView = coordinator.installWebView(with: initialURL, in: embeddedView)

        coordinator.onAppRestartClicked(url: "about:blank")

        let replacement = try #require(embeddedView.webView)
        #expect(replacement !== initialWebView)
        #expect(initialWebView.superview == nil)
        #expect(replacement.superview === embeddedView)
    }

    @Test
    func invalidRestartURLKeepsTheInstalledWebView() throws {
        let coordinator = makeCoordinator()
        let embeddedView = PopupEmbeddedView()
        let url = try #require(URL(string: "about:blank"))
        let webView = coordinator.installWebView(with: url, in: embeddedView)

        coordinator.onAppRestartClicked(url: "http://[::1")

        #expect(embeddedView.webView === webView)
        #expect(webView.superview === embeddedView)
    }

    @Test
    func loadPageReturnsURLFromInjectedLoader() async throws {
        let expectedURL = try #require(URL(string: "https://example.com"))
        let webView = WKWebView()
        var receivedWebView: WKWebView?
        let coordinator = makeCoordinator(pageLoader: { webView in
            receivedWebView = webView
            return expectedURL
        })

        let loadedURL = try await coordinator.loadPage(for: webView)

        #expect(loadedURL == expectedURL)
        #expect(receivedWebView === webView)
    }

    @Test
    func loadPagePropagatesInjectedLoaderError() async {
        let coordinator = makeCoordinator(pageLoader: { _ in
            throw URLError(.badURL)
        })

        await #expect(throws: URLError.self) {
            try await coordinator.loadPage(for: WKWebView())
        }
    }

    private func makeCoordinator(
        pageLoader: (@MainActor (WKWebView) async throws -> URL)? = nil
    ) -> PopupWebViewCoordinator {
        PopupWebViewCoordinator(
            logger: Logger(),
            onEvent: { _ in },
            onPageLoadCompleted: {},
            pageLoader: pageLoader
        )
    }
}
