//------------------------------------------------------------------------------
//  File:          PlacementStubbedUITests.swift
//  Author(s):     Bread Financial
//
//  Description:   Example UI test demonstrating Option 1 — intercepting the
//                 BreadPartners SDK's HTTP traffic with StubURLProtocol so the
//                 UI test runs fully offline with deterministic responses.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import XCTest

final class PlacementStubbedUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    func testPALAPlacement() throws {
        let app = XCUIApplication()
        app.enableHTTPStubs([
            Fixtures.PALAPlacement,
        ])
        app.launch()

        // The Placement tab is the default tab.
        let generateButton = app.buttons["Generate Placement"]
        XCTAssertTrue(
            generateButton.waitForExistence(timeout: 10),
            "Generate Placement button should be visible on launch"
        )

        generateButton.tap()

        // The request is served from the stub, so the app should settle without
        // hanging on the network. Assert the UI is still responsive.
        XCTAssertTrue(
            generateButton.waitForExistence(timeout: 10),
            "App should remain responsive after a stubbed placement request"
        )

        let expectedText =
            "Pay as low as $255/mo for 12 months with the Zales Credit Card for a total payment of $3059."
        let placementText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] %@", expectedText)
        ).firstMatch

        XCTAssertTrue(
            placementText.waitForExistence(timeout: 10),
            "Expected rendered PALA placement text to display on screen: \(expectedText)"
        )
    }
    
    func testRTPSPlacement() throws {
        let app = XCUIApplication()
        app.enableHTTPStubs([
            Fixtures.RTPSConfig,
            Fixtures.RTPSPrescreen,
            Fixtures.RTPSGeneratePlacemnt,
        ])
        app.launch()

        // The Placement tab is the default tab.
       let rtpsTab = app.tabBars.buttons["RTPS"]
        XCTAssertTrue(rtpsTab.waitForExistence(timeout: 10), "RTPS tab should be visible on launch")
        rtpsTab.tap()

        let testRTPSButton = app.buttons["Test RTPS"]
        XCTAssertTrue(testRTPSButton.waitForExistence(timeout: 10), "Test RTPS button should exist")
        var swipes = 0
        while !testRTPSButton.isHittable && swipes < 10 {
            app.swipeUp()
            swipes += 1
        }
        testRTPSButton.tap()
        
        let overlay = app.webViews.firstMatch
        XCTAssertTrue(overlay.waitForExistence(timeout: 15), "RTPS overlay should appear")

    }
        
}
