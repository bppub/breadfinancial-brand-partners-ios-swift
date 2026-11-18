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
        XCTAssertEqual(app.staticTexts["link-result"].label, "Plain link tapped 1")
        app.staticTexts["Plain linked text variant"].tap()
        XCTAssertEqual(app.staticTexts["link-result"].label, "Plain link tapped 2")

        app.staticTexts["Attributed text variant"].tap()
        XCTAssertEqual(app.staticTexts["link-result"].label, "Attributed link tapped")

        app.descendants(matching: .any)["UIKit link text"].tap()
        XCTAssertEqual(app.staticTexts["link-result"].label, "UIKit link tapped")

        let noActionTextView = app.descendants(matching: .textView)
            .matching(identifier: "UIKit no-action text")
            .firstMatch
        XCTAssertTrue(noActionTextView.waitForExistence(timeout: 5))
        noActionTextView.tap()
        XCTAssertEqual(app.staticTexts["link-result"].label, "UIKit no-action tapped")
    }

    @MainActor
    func testLegacyLabelRepresentableRendersUpdatesAndForwardsTap() {
        let app = XCUIApplication()
        app.launch(host: "PlacementTextComponentsTestHost")

        let legacyLink = app.descendants(matching: .any)["legacy-label"]
        XCTAssertTrue(legacyLink.waitForExistence(timeout: 5))
        XCTAssertEqual(legacyLink.label, "Legacy UILabel link")
        legacyLink.tap()
        XCTAssertEqual(app.staticTexts["link-result"].label, "Original legacy handler")

        app.buttons["update-legacy-label"].tap()
        let updated = NSPredicate(format: "label == %@", "Updated legacy UILabel link")
        expectation(for: updated, evaluatedWith: legacyLink)
        waitForExpectations(timeout: 5)

        legacyLink.tap()
        XCTAssertEqual(app.staticTexts["link-result"].label, "Updated legacy handler")
    }

    @MainActor
    func testLinkWithoutHandlerCanBeTapped() {
        let app = XCUIApplication()
        app.launch(host: "PlacementTextComponentsTestHost")

        let link = app.staticTexts["no-action-link"]
        if !link.isHittable {
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(link.waitForExistence(timeout: 5))
        link.tap()
        XCTAssertEqual(app.staticTexts["link-result"].label, "Links ready")
    }
}
