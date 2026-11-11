//------------------------------------------------------------------------------
//  File:          WKWebViewTestAssertions.swift
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

enum WKWebViewTestAssertions {
    @MainActor
    static func assertStatus(
        _ expectedStatus: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let status = app.staticTexts["webkit-navigation-status"]
        XCTAssertTrue(status.waitForExistence(timeout: 10), file: file, line: line)

        let terminalFailurePrefixes = [
            "Navigation failed:",
            "Web Content process terminated",
            "JavaScript update failed:",
            "PDF generation failed:",
            "PDF output invalid",
            "WebView unavailable",
        ]
        let terminalStatus = NSCompoundPredicate(
            orPredicateWithSubpredicates: [
                NSPredicate(format: "label == %@", expectedStatus)
            ] + terminalFailurePrefixes.map { NSPredicate(format: "label BEGINSWITH %@", $0) }
        )
        let expectation = XCTNSPredicateExpectation(predicate: terminalStatus, object: status)
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: 45),
            .completed,
            "Timed out waiting for '\(expectedStatus)'; current WebKit status: \(status.label)",
            file: file,
            line: line
        )
        XCTAssertEqual(status.label, expectedStatus, file: file, line: line)
    }
}
