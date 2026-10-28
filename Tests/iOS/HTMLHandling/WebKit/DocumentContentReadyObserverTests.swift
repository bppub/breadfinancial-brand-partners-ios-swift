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

import Foundation
import WebKit
import Testing

@testable import BreadPartners

@MainActor
@Suite(.serialized)
struct DocumentContentReadyObserverTests {
    @Test
    func notifiesWhenBodyAlreadyContainsContentAtNavigationFinish() async {
        let webView = WKWebView()
        var navigationDelegate: NavigationDelegateForwarder?

        let didBecomeReady = await waitForCallback { signal in
            let observer = DocumentContentReadyObserver(webView: webView) { readyWebView in
                #expect(readyWebView === webView)
                signal.yield(())
                signal.finish()
            }
            navigationDelegate = NavigationDelegateForwarder(observer: observer)
            webView.navigationDelegate = navigationDelegate

            webView.loadHTMLString("<html><body><p>Disclosure</p></body></html>", baseURL: nil)
        }

        #expect(didBecomeReady, "Timed out waiting for document content readiness")
    }

    @Test
    func notifiesWhenBodyBecomesPopulatedAfterNavigationFinish() async {
        let webView = WKWebView()
        var navigationDelegate: NavigationDelegateForwarder?

        let didBecomeReady = await waitForCallback { signal in
            let observer = DocumentContentReadyObserver(webView: webView) { readyWebView in
                #expect(readyWebView === webView)
                signal.yield(())
                signal.finish()
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

        #expect(didBecomeReady, "Timed out waiting for document content readiness")
    }
}

@MainActor
private func waitForCallback(
    timeout: UInt64 = 60_000_000_000,
    register: (AsyncStream<Void>.Continuation) -> Void
) async -> Bool {
    let (stream, signal) = AsyncStream<Void>.makeStream()

    register(signal)

    return await withTaskGroup(of: Bool.self) { group in
        group.addTask {
            for await _ in stream {
                return true
            }
            return false
        }

        group.addTask {
            try? await Task.sleep(nanoseconds: UInt64(timeout))
            return false
        }

        let didReceiveCallback = await group.next() ?? false

        group.cancelAll()

        return didReceiveCallback
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
