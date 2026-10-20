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

    /// Launches the app with HTTP stubbing enabled and taps "Generate Placement".
    /// Because `StubURLProtocol.isolateUnmatchedRequests` defaults to `true`, no
    /// request escapes to the real network — unmatched calls get an empty `{}` 200.
    func testGeneratePlacementWithStubbedNetwork() throws {
        let app = XCUIApplication()
        app.enableHTTPStubs([
            Fixtures.brandConfig,       // required: fetched during SDK setup
            Fixtures.brandStyle,
            Fixtures.generatePlacements,
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

        // NOTE: To assert on *rendered placement content*, replace
        // `Fixtures.generatePlacements` with a captured real response and add an
        // accessibility identifier to the rendered placement view, e.g.:
        //   XCTAssertTrue(app.staticTexts["placementText"].waitForExistence(timeout: 10))
    }

    /// Demonstrates simulating a server error by stubbing a non-2xx status.
    func testPlacementHandlesServerError() throws {
        let app = XCUIApplication()
        // Brand config succeeds so setup completes; placements returns a 500.
        app.enableHTTPStubs([
            Fixtures.brandConfig,
            Fixtures.brandStyle,
            HTTPStub(
                match: "/generatePlacements",
                jsonString: #"{ "message": "Simulated failure" }"#,
                statusCode: 500
            ),
        ])
        app.launch()

        let generateButton = app.buttons["Generate Placement"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 10))
        generateButton.tap()

        // App should surface the error path gracefully without crashing.
        XCTAssertTrue(app.buttons["Generate Placement"].waitForExistence(timeout: 10))
    }
    
    func testNewPlacement() throws {
        let placementsBody = #"""
                {
                  "placementContent" : [
                    {
                      "metadata" : {
                        "placementId" : "e6595a74-659d-431b-88d4-0146a5b4578c",
                        "productType" : "CARD",
                        "messageId" : "928d351d-06f5-4251-afd1-ed0bd2de4775",
                        "templateId" : "pala-template-bold",
                        "adobe" : null
                      },
                      "id" : "0",
                      "contentType" : "SSRTextPlacementContent",
                      "contentData" : {
                        "htmlContent" : "<div class=\"ep-text-placement\"data-action-type=\"NO_ACTION\" data-action-target=\"placement-primary-cta\"> Pay as low as <strong><span class=\"alliance-as-low-as-amount\">$255\/mo<\/span> for 12 months<\/strong> with the Zales Credit Card for a total payment of $3059.<sup>♢<\/sup> <\/div>"
                      }
                    }
                  ],
                  "placements" : [
                    {
                      "id" : "e6595a74-659d-431b-88d4-0146a5b4578c",
                      "content" : {
                        "contentId" : "0"
                      },
                      "domId" : "",
                      "renderContext" : {
                        "channel" : "",
                        "PRICE" : 299900,
                        "ENV" : "STAGE",
                        "STORE_NUMBER" : "8883",
                        "UPQ_PARAMS" : "storeNumber=8883&location=checkout&checkoutAmount=2999.00&clientKey=653b0802-06a5-468a-aa94-d782a27f3c7b&epPlacementId=e6595a74-659d-431b-88d4-0146a5b4578c&embedded=true",
                        "LOCATION" : "checkout",
                        "subchannel" : "",
                        "ALLOW_CHECKOUT" : false,
                        "DATETIME" : "2026-10-20T15:37:51.861263920-04:00"
                      }
                    }
                  ]
                }
                """#
        
        
        let app = XCUIApplication()
        app.enableHTTPStubs([
            Fixtures.brandConfig,       // required: fetched during SDK setup
            Fixtures.brandStyle,
            HTTPStub(
                match: "/generatePlacements",
                jsonString: placementsBody,
                statusCode: 200
            ),
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

        // NOTE: To assert on *rendered placement content*, replace
        // `Fixtures.generatePlacements` with a captured real response and add an
        // accessibility identifier to the rendered placement view, e.g.:
        //   XCTAssertTrue(app.staticTexts["placementText"].waitForExistence(timeout: 10))
        
        // Assert the rendered Zales placement text appears on screen. The SDK
        // strips the HTML tags and the trailing "♢" superscript, so we match on
        // the plain-text sentence it produces. A CONTAINS predicate keeps the
        // match resilient to surrounding whitespace.
        let expectedText =
            "Pay as low as $255/mo for 12 months with the Zales Credit Card for a total payment of $3059."
        let placementText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] %@", expectedText)
        ).firstMatch

        XCTAssertTrue(
            placementText.waitForExistence(timeout: 10),
            "Expected rendered Zales placement text to display on screen: \(expectedText)"
        )
    }
        
}
