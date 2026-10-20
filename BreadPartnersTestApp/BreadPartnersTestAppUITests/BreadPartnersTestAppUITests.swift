//
//  BreadPartnersTestAppUITests.swift
//  BreadPartnersTestAppUITests
//
//  Created by Joncarlos Tavarez on 10/20/26.
//

import XCTest

final class BreadPartnersTestAppUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testAppLaunchesAndShowsCoreUI() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // The app should reach a running state after launch.
        XCTAssertEqual(app.state, .runningForeground, "App did not reach the foreground after launch.")

        // The navigation bar title set in ContentView should be present.
        XCTAssertTrue(
            app.staticTexts["Bread Partners Test App"].waitForExistence(timeout: 10),
            "Expected the navigation title 'Bread Partners Test App' to be visible."
        )

        // The main TabView exposes two tabs: Placement and RTPS.
        let placementTab = app.tabBars.buttons["Placement"]
        let rtpsTab = app.tabBars.buttons["RTPS"]
        XCTAssertTrue(
            placementTab.waitForExistence(timeout: 5),
            "Expected the 'Placement' tab to be visible."
        )
        XCTAssertTrue(
            rtpsTab.waitForExistence(timeout: 5),
            "Expected the 'RTPS' tab to be visible."
        )
    }

    @MainActor
    func testCanSwitchBetweenTabs() throws {
        let app = XCUIApplication()
        app.launch()

        let placementTab = app.tabBars.buttons["Placement"]
        let rtpsTab = app.tabBars.buttons["RTPS"]

        XCTAssertTrue(
            placementTab.waitForExistence(timeout: 10),
            "Expected the 'Placement' tab to exist before switching tabs."
        )

        // Navigate to the RTPS tab and confirm it becomes selected.
        rtpsTab.tap()
        XCTAssertTrue(rtpsTab.isSelected, "Expected the 'RTPS' tab to be selected after tapping it.")

        // Navigate back to the Placement tab and confirm it becomes selected.
        placementTab.tap()
        XCTAssertTrue(placementTab.isSelected, "Expected the 'Placement' tab to be selected after tapping it.")
    }
}
