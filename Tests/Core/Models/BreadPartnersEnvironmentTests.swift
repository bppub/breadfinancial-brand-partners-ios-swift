//------------------------------------------------------------------------------
//  File:          BreadPartnersEnvironmentTests.swift
//  Author(s):     Bread Financial
//  Date:          02 September 2026
//
//  Descriptions:  Unit tests for BreadPartnersEnvironment.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import XCTest
@testable import BreadPartnersSDKCore

final class BreadPartnersEnvironmentTests: XCTestCase {
    func testEnvironmentValues() {
        XCTAssertEqual(BreadPartnersEnvironment.stage.rawValue, "STAGE")
        XCTAssertEqual(BreadPartnersEnvironment.prod.rawValue, "PROD")
        XCTAssertEqual(BreadPartnersEnvironment.uat.rawValue, "UAT")
    }

    func testEnvironmentConformance() {
        let allCases = BreadPartnersEnvironment.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.stage))
        XCTAssertTrue(allCases.contains(.prod))
        XCTAssertTrue(allCases.contains(.uat))
    }
}
