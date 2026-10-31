//------------------------------------------------------------------------------
//  File:          PlacementTextComponentsUITests.swift
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

final class PlacementTextComponentsUITests: XCTestCase {
    @MainActor
    func testTextAndLinkVariantsRenderTogether() {
        let app = XCUIApplication()
        app.launch(host: "PlacementTextComponentsTestHost")

        XCTAssertTrue(app.staticTexts["Default text variant"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Styled text variant"].exists)
        XCTAssertTrue(app.staticTexts["Plain linked text variant"].exists)
        XCTAssertTrue(app.staticTexts["Attributed text variant"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["UIKit link text"].exists)
    }

    @MainActor
    func testButtonVariantsForwardActions() {
        let app = XCUIApplication()
        app.launch(host: "PlacementTextComponentsTestHost")

        app.buttons["Default action"].tap()
        XCTAssertEqual(app.staticTexts["button-result"].label, "Default button tapped")

        app.buttons["Styled action"].tap()
        XCTAssertEqual(app.staticTexts["button-result"].label, "Styled button tapped")
    }

    @MainActor
    func testPlainAndAttributedLinkVariantsForwardTaps() {
        let app = XCUIApplication()
        app.launch(host: "PlacementTextComponentsTestHost")

        app.staticTexts["Plain linked text variant"].tap()
        XCTAssertEqual(app.staticTexts["link-result"].label, "Plain link tapped")

        app.staticTexts["Attributed text variant"].tap()
        XCTAssertEqual(app.staticTexts["link-result"].label, "Attributed link tapped")

        app.descendants(matching: .any)["UIKit link text"].tap()
        XCTAssertEqual(app.staticTexts["link-result"].label, "UIKit link tapped")
    }
}
