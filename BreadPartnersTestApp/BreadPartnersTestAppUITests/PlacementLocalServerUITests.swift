//------------------------------------------------------------------------------
//  File:          PlacementLocalServerUITests.swift
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

@MainActor
final class PlacementLocalServerUITests: XCTestCase {
    private var server: MockHTTPServer?

    override func setUp() async throws {
        try await super.setUp()
    }

    override func tearDown() async throws {
        await server?.stop()
        server = nil
        try await super.tearDown()
    }

    func testPALAPlacementFromLocalServer() async throws {
        let server = try MockHTTPServer(stubs: [Fixtures.PALAPlacement])
        self.server = server
        let baseURL = try await server.start()

        let app = XCUIApplication()
        app.launchEnvironment[MockServerKeys.baseURLKey] = baseURL.absoluteString
        app.launch()

        let generateButton = app.buttons["Generate Placement"]
        XCTAssertTrue(
            generateButton.waitForExistence(timeout: 10),
            "Generate Placement button should be visible on launch"
        )

        generateButton.tap()

        let expectedText =
            "Pay as low as $255/mo for 12 months with the Zales Credit Card for a total payment of $3059."
        let placementText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] %@", expectedText)
        ).firstMatch

        XCTAssertTrue(
            placementText.waitForExistence(timeout: 10),
            "Expected rendered PALA placement text to display on screen: \(expectedText)"
        )

        // Proves the placement came from the local server rather than the real API.
        let paths = await server.receivedPaths()
        XCTAssertTrue(
            paths.contains { $0.hasSuffix("/generatePlacements") },
            "Local server should have received /generatePlacements; got \(paths)"
        )
    }
    
    func testRTPSFromLocalServer() async throws {
        let server = try MockHTTPServer(stubs: [Fixtures.RTPSConfig,
                                                Fixtures.RTPSPrescreen,
                                                Fixtures.RTPSGeneratePlacemnt,
                                               ])
        self.server = server
        let baseURL = try await server.start()

        let app = XCUIApplication()
        app.launchEnvironment[MockServerKeys.baseURLKey] = baseURL.absoluteString
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
        XCTAssertTrue(overlay.waitForExistence(timeout: 30), "RTPS overlay should appear")
    }

}
