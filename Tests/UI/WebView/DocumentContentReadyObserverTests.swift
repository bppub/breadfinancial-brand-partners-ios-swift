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

import XCTest

@testable import BreadPartners

final class DocumentContentReadyObserverTests: XCTestCase {
    @MainActor
    func testNotifiesWhenBodyAlreadyContainsContentAtNavigationFinish() {
        let app = XCUIApplication()
        app.launch(host: "WKWebViewNavigationTestHost")

        app.buttons["load-document-with-content"].tap()

        WKWebViewTestAssertions.assertStatus("Document ready", in: app)
    }

    @MainActor
    func testNotifiesWhenBodyBecomesPopulatedAfterNavigationFinish() {
        let app = XCUIApplication()
        app.launch(host: "WKWebViewNavigationTestHost")

        app.buttons["load-document-with-delayed-content"].tap()

        WKWebViewTestAssertions.assertStatus("Document ready", in: app)
    }
}
