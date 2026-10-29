//------------------------------------------------------------------------------
//  File:          NavigationConfirmationPresenterUITests.swift
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

final class NavigationConfirmationPresenterUITests: XCTestCase {
    @MainActor
    func testStayButtonInvokesStayCallback() {
        let app = XCUIApplication()
        app.launch(host: "NavigationConfirmationTestHost")

        app.buttons["show-confirmation"].tap()

        let alert = app.alerts["Confirm Navigation"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Stay"].tap()

        XCTAssertTrue(app.staticTexts["Stay selected"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLeaveButtonInvokesLeaveCallback() {
        let app = XCUIApplication()
        app.launch(host: "NavigationConfirmationTestHost")

        app.buttons["show-confirmation"].tap()

        let alert = app.alerts["Confirm Navigation"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Leave"].tap()

        XCTAssertTrue(app.staticTexts["Leave selected"].waitForExistence(timeout: 5))
    }
}
