//------------------------------------------------------------------------------
//  File:          WKNavigationDelegateSpy.swift
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

/// A small `WKNavigationDelegate` that exposes navigation completion to tests.
///
/// Use this instead of defining a one-off delegate in each test that needs to react to
/// `didFinish`. Keep a strong reference while navigation is in progress because the web view's
/// navigation delegate is weakly held.
///
/// - Parameter onFinish: Called for each completed navigation with its web view and navigation.
@MainActor
final class WKNavigationDelegateSpy: NSObject, WKNavigationDelegate {
    private let onFinish: (WKWebView, WKNavigation?) -> Void

    init(onFinish: @escaping (WKWebView, WKNavigation?) -> Void) {
        self.onFinish = onFinish
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        onFinish(webView, navigation)
    }
}
