//------------------------------------------------------------------------------
//  File:          WKNavigationDelegateSpyTests.swift
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
import WebKit

@MainActor
@Suite
struct WKNavigationDelegateSpyTests {
    @Test
    func forwardsCompletedWebViewAndNavigationToClosure() {
        let webView = WKWebView()
        var receivedWebView: WKWebView?
        var receivedNilNavigation = false

        let delegate = WKNavigationDelegateSpy { finishedWebView, navigation in
            receivedWebView = finishedWebView
            receivedNilNavigation = navigation == nil
        }

        delegate.webView(webView, didFinish: nil)

        #expect(receivedWebView === webView)
        #expect(receivedNilNavigation)
    }

    @Test
    func callsClosureForEachFinishedNavigation() {
        let webView = WKWebView()
        var callbackCount = 0
        let delegate = WKNavigationDelegateSpy { _, _ in
            callbackCount += 1
        }

        delegate.webView(webView, didFinish: nil)
        delegate.webView(webView, didFinish: nil)

        #expect(callbackCount == 2)
    }
}
