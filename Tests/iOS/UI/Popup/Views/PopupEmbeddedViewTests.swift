//------------------------------------------------------------------------------
//  File:          PopupEmbeddedViewTests.swift
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
struct PopupEmbeddedViewTests {
    @Test
    func installsWebViewWithInsetConstraints() {
        let container = PopupEmbeddedView()
        let webView = WKWebView()

        container.install(webView)

        #expect(container.webView === webView)
        #expect(webView.superview === container)
        #expect(constraints(for: webView, in: container).count == 4)
    }

    @Test
    func replacingWebViewRemovesOldViewAndConstraints() {
        let container = PopupEmbeddedView()
        let oldWebView = WKWebView()
        let newWebView = WKWebView()

        container.install(oldWebView)
        let oldConstraints = constraints(for: oldWebView, in: container)

        container.install(newWebView)

        #expect(oldWebView.superview == nil)
        #expect(oldConstraints.allSatisfy { !$0.isActive })
        #expect(container.webView === newWebView)
        #expect(newWebView.superview === container)
        #expect(constraints(for: newWebView, in: container).count == 4)
    }

    private func constraints(for view: UIView, in container: UIView) -> [NSLayoutConstraint] {
        container.constraints.filter {
            ($0.firstItem as? UIView) === view || ($0.secondItem as? UIView) === view
        }
    }
}
