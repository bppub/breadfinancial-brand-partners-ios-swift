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
    // MARK: - Raw Value Mapping

    func testStageRawValue() {
        XCTAssertEqual(BreadPartnersEnvironment.stage.rawValue, "STAGE")
    }

    func testProdRawValue() {
        XCTAssertEqual(BreadPartnersEnvironment.prod.rawValue, "PROD")
    }

    func testUatRawValue() {
        XCTAssertEqual(BreadPartnersEnvironment.uat.rawValue, "UAT")
    }

    // MARK: - Initialisation from Raw Value

    func testInitFromStage() {
        XCTAssertEqual(BreadPartnersEnvironment(rawValue: "STAGE"), .stage)
    }

    func testInitFromProd() {
        XCTAssertEqual(BreadPartnersEnvironment(rawValue: "PROD"), .prod)
    }

    func testInitFromUat() {
        XCTAssertEqual(BreadPartnersEnvironment(rawValue: "UAT"), .uat)
    }

    // MARK: - Invalid Raw Values

    func testInitFromUnknownRawValue() {
        XCTAssertNil(BreadPartnersEnvironment(rawValue: "UNKNOWN"))
    }

    func testInitFromEmptyString() {
        XCTAssertNil(BreadPartnersEnvironment(rawValue: ""))
    }

    func testInitFromLowercaseRawValue() {
        XCTAssertNil(BreadPartnersEnvironment(rawValue: "stage"))
        XCTAssertNil(BreadPartnersEnvironment(rawValue: "prod"))
        XCTAssertNil(BreadPartnersEnvironment(rawValue: "uat"))
    }

    // MARK: - Equality

    func testCaseEquality() {
        XCTAssertEqual(BreadPartnersEnvironment.stage, BreadPartnersEnvironment.stage)
        XCTAssertEqual(BreadPartnersEnvironment.prod, BreadPartnersEnvironment.prod)
        XCTAssertEqual(BreadPartnersEnvironment.uat, BreadPartnersEnvironment.uat)
    }

    func testCaseInequality() {
        XCTAssertNotEqual(BreadPartnersEnvironment.stage, BreadPartnersEnvironment.prod)
        XCTAssertNotEqual(BreadPartnersEnvironment.prod, BreadPartnersEnvironment.uat)
        XCTAssertNotEqual(BreadPartnersEnvironment.stage, BreadPartnersEnvironment.uat)
    }

    // MARK: - CaseIterable

    func testAllCasesCount() {
        XCTAssertEqual(BreadPartnersEnvironment.allCases.count, 3)
    }

    func testAllCasesContents() {
        XCTAssertTrue(BreadPartnersEnvironment.allCases.contains(.stage))
        XCTAssertTrue(BreadPartnersEnvironment.allCases.contains(.prod))
        XCTAssertTrue(BreadPartnersEnvironment.allCases.contains(.uat))
    }
}
