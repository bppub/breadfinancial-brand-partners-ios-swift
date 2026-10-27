//------------------------------------------------------------------------------
//  File:          MockHttpResponseTests.swift
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

/// Tests for `MockHttpResponse`: the defaults it applies and that custom values are kept.
final class MockHttpResponseTests: XCTestCase {
    func testDataInitializerDefaultsToOKAndJSONContentType() {
        let body = Data("{}".utf8)

        let response = MockHttpResponse(match: "/path", json: body)

        XCTAssertEqual(response.match, "/path")
        XCTAssertEqual(response.json, body)
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.headers, ["Content-Type": "application/json"])
    }

    func testStringInitializerEncodesBodyAsUTF8() {
        let response = MockHttpResponse(match: "/path", jsonString: #"{ "name": "café" }"#)

        XCTAssertEqual(response.json, Data(#"{ "name": "café" }"#.utf8))
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.headers, ["Content-Type": "application/json"])
    }

    func testCustomStatusCodeAndHeadersArePreserved() {
        let response = MockHttpResponse(
            match: "/path",
            jsonString: "{}",
            statusCode: 503,
            headers: ["Content-Type": "text/plain", "X-Test": "1"]
        )

        XCTAssertEqual(response.statusCode, 503)
        XCTAssertEqual(response.headers, ["Content-Type": "text/plain", "X-Test": "1"])
    }
}
