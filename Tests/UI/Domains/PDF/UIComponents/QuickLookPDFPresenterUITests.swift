//------------------------------------------------------------------------------
//  File:          QuickLookPDFPresenterUITests.swift
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

final class QuickLookPDFPresenterUITests: XCTestCase {
    @MainActor
    func testPDFPreviewCanBePresentedAndDismissed() {
        let app = XCUIApplication()
        app.launch(host: "QuickLookPDFPresenterTestHost")

        app.buttons["show-pdf-preview"].tap()

        XCTAssertTrue(app.staticTexts["PDF preview presented"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 10))

        let closeButton = app.buttons["QLOverlayDoneButtonAccessibilityIdentifier"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 10))
        closeButton.tap()

        XCTAssertTrue(
            app.staticTexts["PDF preview dismissed"].waitForExistence(timeout: 30)
        )
    }
}
