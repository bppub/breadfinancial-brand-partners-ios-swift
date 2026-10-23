//------------------------------------------------------------------------------
//  File:          RTPSUITest.swift
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
final class RTPSUITest: XCTestCase {
    private var server: MockHTTPServer?

    override func setUp() async throws {
        try await super.setUp()
    }

    override func tearDown() async throws {
        XCUIApplication().terminate()
        await server?.stop()
        server = nil
        try await super.tearDown()
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
        app.launchFresh()

        // The Placement tab is the default tab.
        let rtpsTab = app.tabBars.buttons["RTPS"]
        XCTAssertTrue(rtpsTab.waitForExistence(timeout: 10), "RTPS tab should be visible on launch")
        rtpsTab.tap()

        app.fillDisclosureSection("Customer Info", with: [
            "First Name": "Jane",
            "Last Name": "Doe",
            "Address 1": "1 Main St",
            "City": "Columbus",
            "State": "OH",
            "Zip Code": "43215",
            "Country": "USA",
        ])

        app.fillDisclosureSection("EpJs Config", with: [
            "API Key": "15a64a51-104d-4ad3-915f-911b6ef63cfd",
        ])
       
        
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
