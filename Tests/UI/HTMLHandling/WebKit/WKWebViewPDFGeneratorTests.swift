//------------------------------------------------------------------------------
//  File:          WKWebViewPDFGeneratorTests.swift
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

final class WKWebViewPDFGeneratorTests: XCTestCase {
    @MainActor
    func testGeneratesPDFDataAfterNavigationFinishes() async throws {
        let webView = WKWebView()
        let navigationFinished = expectation(description: "WebView navigation finished")
        var didFinishNavigation = false
        var navigationError: Error?
        let navigationDelegate = PDFNavigationDelegate(
            onFinish: {
                didFinishNavigation = true
                navigationFinished.fulfill()
            },
            onFailure: { error in
                navigationError = error
                navigationFinished.fulfill()
            }
        )
        webView.navigationDelegate = navigationDelegate

        webView.loadHTMLString("<html><body><p>PDF content</p></body></html>", baseURL: nil)

        await fulfillment(of: [navigationFinished], timeout: 30)
        guard didFinishNavigation else {
            if let navigationError {
                XCTFail("WKWebView navigation failed: \(navigationError)")
            } else {
                XCTFail("WKWebView did not call didFinish before timeout")
            }
            return
        }

        let pdfData = try await WKWebViewPDFGenerator().generate(from: webView)

        XCTAssertTrue(pdfData.starts(with: Data("%PDF".utf8)))
    }
}

@MainActor
private final class PDFNavigationDelegate: NSObject, WKNavigationDelegate {
    private let onFinish: () -> Void
    private let onFailure: (Error) -> Void

    init(onFinish: @escaping () -> Void, onFailure: @escaping (Error) -> Void) {
        self.onFinish = onFinish
        self.onFailure = onFailure
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        onFinish()
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        onFailure(error)
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        onFailure(error)
    }
}
