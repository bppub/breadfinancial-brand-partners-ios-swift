//------------------------------------------------------------------------------
//  File:          DocumentContentReadyObserver.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import WebKit

final class DocumentContentReadyObserver: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    private static let messageHandlerName = "documentContentReady"

    weak var webView: WKWebView?
    private let onReady: @MainActor (WKWebView) async -> Void

    init(webView: WKWebView, onReady: @escaping @MainActor (WKWebView) async -> Void) {
        self.webView = webView
        self.onReady = onReady

        super.init()

        let controller = webView.configuration.userContentController
        controller.removeScriptMessageHandler(forName: Self.messageHandlerName)
        controller.add(self, name: Self.messageHandlerName)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let js = """
            (function() {
                function checkAndNotify() {
                    if (document.body && document.body.innerHTML.trim().length > 0) {
                        window.webkit.messageHandlers.\(Self.messageHandlerName).postMessage("ready");
                        return true;
                    }
                    return false;
                }
                if (!checkAndNotify()) {
                    var observer = new MutationObserver(function() {
                        if (checkAndNotify()) { observer.disconnect(); }
                    });
                    observer.observe(document.documentElement, { childList: true, subtree: true });
                }
            })();
            """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == Self.messageHandlerName, let webView else { return }

        userContentController.removeScriptMessageHandler(forName: Self.messageHandlerName)

        Task { @MainActor [onReady, webView] in
            await onReady(webView)
        }
    }
}
