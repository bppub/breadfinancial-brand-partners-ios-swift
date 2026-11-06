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
import XCTest

@testable import BreadPartners

final class DocumentContentReadyObserverTests: XCTestCase {
    @MainActor
    func testNotifiesWhenBodyAlreadyContainsContentAtNavigationFinish() async {
        let webView = WKWebView()
        var didFinishNavigation = false
        var didBecomeReady = false
        let navigationFinished = expectation(description: "WebView navigation finished")
        let contentBecameReady = expectation(description: "Document content became ready")
        let observer = DocumentContentReadyObserver(webView: webView) { readyWebView in
            XCTAssertTrue(readyWebView === webView)
            didBecomeReady = true
            contentBecameReady.fulfill()
        }
        let navigationDelegate = WKNavigationDelegateSpy { finishedWebView, navigation in
            observer.webView(finishedWebView, didFinish: navigation)
            didFinishNavigation = true
            navigationFinished.fulfill()
        }
        webView.navigationDelegate = navigationDelegate

        webView.loadHTMLString("<html><body><p>Disclosure</p></body></html>", baseURL: nil)

        await fulfillment(of: [navigationFinished, contentBecameReady], timeout: 30, enforceOrder: true)
        XCTAssertTrue(didFinishNavigation, "WKWebView did not call didFinishNavigation")
        XCTAssertTrue(didBecomeReady, "The observer did not report document readiness")
    }

    @MainActor
    func testNotifiesWhenBodyBecomesPopulatedAfterNavigationFinish() async {
        let webView = WKWebView()
        var didFinishNavigation = false
        var didBecomeReady = false
        let navigationFinished = expectation(description: "WebView navigation finished")
        let contentBecameReady = expectation(description: "Document content became ready")
        let observer = DocumentContentReadyObserver(webView: webView) { readyWebView in
            XCTAssertTrue(readyWebView === webView)
            didBecomeReady = true
            contentBecameReady.fulfill()
        }
        let navigationDelegate = WKNavigationDelegateSpy { finishedWebView, navigation in
            observer.webView(finishedWebView, didFinish: navigation)
            didFinishNavigation = true
            navigationFinished.fulfill()
            Task { @MainActor in
                do {
                    _ = try await webView.evaluateJavaScript(
                        "document.body.innerHTML = '<p>Disclosure</p>'"
                    )
                } catch {
                    XCTFail("Expected JavaScript evaluation to succeed: \(error)")
                }
            }
        }
        webView.navigationDelegate = navigationDelegate

        webView.loadHTMLString("<html><body></body></html>", baseURL: nil)

        await fulfillment(of: [navigationFinished, contentBecameReady], timeout: 30, enforceOrder: true)
        XCTAssertTrue(didFinishNavigation, "WKWebView did not call didFinishNavigation")
        XCTAssertTrue(didBecomeReady, "The observer did not report document readiness")
    }
}
