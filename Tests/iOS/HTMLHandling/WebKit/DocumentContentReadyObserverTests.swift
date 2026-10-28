//------------------------------------------------------------------------------
//  File:          DocumentContentReadyObserverTests.swift
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
import Testing

@testable import BreadPartners

@MainActor
@Suite(.serialized)
struct DocumentContentReadyObserverTests {
    @Test(.timeLimit(.minutes(1)))
    func notifiesWhenBodyAlreadyContainsContentAtNavigationFinish() async {
        let webView = WKWebView()
        var navigationDelegate: NavigationDelegateForwarder?

        await confirmation("Document content readiness is reported") { readyConfirmation in
            await withCheckedContinuation { continuation in
                let observer = DocumentContentReadyObserver(webView: webView) { readyWebView in
                    #expect(readyWebView === webView)
                    readyConfirmation()
                    continuation.resume()
                }
                navigationDelegate = NavigationDelegateForwarder(observer: observer)
                webView.navigationDelegate = navigationDelegate

                webView.loadHTMLString("<html><body><p>Disclosure</p></body></html>", baseURL: nil)
            }
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func notifiesWhenBodyBecomesPopulatedAfterNavigationFinish() async {
        let webView = WKWebView()
        var navigationDelegate: NavigationDelegateForwarder?

        await confirmation("Document content readiness is reported") { readyConfirmation in
            await withCheckedContinuation { continuation in
                let observer = DocumentContentReadyObserver(webView: webView) { readyWebView in
                    #expect(readyWebView === webView)
                    readyConfirmation()
                    continuation.resume()
                }
                navigationDelegate = NavigationDelegateForwarder(observer: observer) {
                    Task { @MainActor in
                        do {
                            _ = try await webView.evaluateJavaScript(
                                "document.body.innerHTML = '<p>Disclosure</p>'"
                            )
                        } catch {
                            Issue.record("Expected JavaScript evaluation to succeed: \(error)")
                        }
                    }
                }
                webView.navigationDelegate = navigationDelegate

                webView.loadHTMLString("<html><body></body></html>", baseURL: nil)
            }
        }
    }
}

@MainActor
private final class NavigationDelegateForwarder: NSObject, WKNavigationDelegate {
    private let observer: DocumentContentReadyObserver
    private let onFinish: () -> Void

    init(observer: DocumentContentReadyObserver, onFinish: @escaping () -> Void = {}) {
        self.observer = observer
        self.onFinish = onFinish
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        observer.webView(webView, didFinish: navigation)
        onFinish()
    }
}
