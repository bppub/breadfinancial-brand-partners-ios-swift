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
import Testing
import WebKit

@testable import BreadPartners

@MainActor
@Suite(.serialized)
struct WKWebViewPDFGeneratorTests {
    @Test
    func generatesPDFDataAfterNavigationFinishes() async throws {
        let webView = WKWebView()
        var navigationDelegate: WKNavigationDelegateSpy?

        let didFinishNavigation = await waitForCallback { signal in
            let delegate = WKNavigationDelegateSpy { _, _ in
                signal.yield(())
                signal.finish()
            }
            navigationDelegate = delegate
            webView.navigationDelegate = delegate
            webView.loadHTMLString("<html><body><p>PDF content</p></body></html>", baseURL: nil)
        }

        #expect(didFinishNavigation, "Timed out waiting for web view navigation")
        withExtendedLifetime(navigationDelegate) {}

        let pdfData = try await WKWebViewPDFGenerator().generate(from: webView)

        #expect(pdfData.starts(with: Data("%PDF".utf8)))
    }
}
