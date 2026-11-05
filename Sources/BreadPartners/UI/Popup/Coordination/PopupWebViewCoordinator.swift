//------------------------------------------------------------------------------
//  File:          PopupWebViewCoordinator.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import UIKit
import WebKit

@MainActor
internal final class PopupWebViewCoordinator: @MainActor AppRestartListener {
    private let webViewManager: BreadFinancialWebViewInterstitial
    private let pageLoader: @MainActor (WKWebView) async throws -> URL
    private let onPageLoadCompleted: () -> Void
    private weak var embeddedView: PopupEmbeddedView?
    private var webView: WKWebView?

    init(
        logger: Logger,
        onEvent: @escaping (BreadPartnerEvents) -> Void,
        onPageLoadCompleted: @escaping () -> Void,
        pageLoader: (@MainActor (WKWebView) async throws -> URL)? = nil
    ) {
        let webViewManager = BreadFinancialWebViewInterstitial(logger: logger, callback: onEvent)
        self.onPageLoadCompleted = onPageLoadCompleted
        self.webViewManager = webViewManager
        self.pageLoader =
            pageLoader ?? { webView in
                try await webViewManager.loadPage(for: webView)
            }
        webViewManager.appRestartListener = self
    }

    func installWebView(with url: URL, in embeddedView: PopupEmbeddedView) -> WKWebView {
        self.embeddedView = embeddedView
        observePageLoadCompletion()

        let webView = webViewManager.createWebView(with: url)
        embeddedView.install(webView)
        self.webView = webView
        return webView
    }

    func loadPage(for webView: WKWebView) async throws -> URL {
        try await pageLoader(webView)
    }

    func onAppRestartClicked(url: String) {
        guard let url = URL(string: url),
            let embeddedView,
            let webView
        else { return }

        webView.stopLoading()
        observePageLoadCompletion()

        let replacement = webViewManager.createWebView(with: url)
        embeddedView.install(replacement)
        self.webView = replacement
    }

    private func observePageLoadCompletion() {
        webViewManager.onPageLoadCompleted = { [weak self] _ in
            self?.onPageLoadCompleted()
        }
    }
}
