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

import XCTest

@testable import BreadPartners

final class WKWebViewPDFGeneratorTests: XCTestCase {
    @MainActor
    func testGeneratesPDFDataAfterNavigationFinishes() {
        let app = XCUIApplication()
        app.launch(host: "WKWebViewNavigationTestHost")

        app.buttons["generate-pdf"].tap()

        WKWebViewTestAssertions.assertStatus("PDF generated", in: app)
    }
}
