//------------------------------------------------------------------------------
//  File:          OfferResponseTests.swift
//  Author(s):     Bread Financial
//  Date:          02 September 2026
//
//  Descriptions:  Unit tests for OfferResponse.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import XCTest
@testable import BreadPartnersSDKCore

final class OfferResponseTests: XCTestCase {
    // MARK: - Raw Value Mapping

    func testYesRawValue() {
        XCTAssertEqual(OfferResponse.yes.rawValue, "YES")
    }

    func testNoRawValue() {
        XCTAssertEqual(OfferResponse.no.rawValue, "NO")
    }

    func testNotMeRawValue() {
        XCTAssertEqual(OfferResponse.notMe.rawValue, "NOT_ME")
    }

    func testAbandonedRawValue() {
        XCTAssertEqual(OfferResponse.abandoned.rawValue, "ABANDONED")
    }

    func testPrescreenNoRawValue() {
        XCTAssertEqual(OfferResponse.prescreenNo.rawValue, "PRESCREEN_NO")
    }

    // MARK: - Initialisation from Raw Value

    func testInitFromYes() {
        XCTAssertEqual(OfferResponse(rawValue: "YES"), .yes)
    }

    func testInitFromNo() {
        XCTAssertEqual(OfferResponse(rawValue: "NO"), .no)
    }

    func testInitFromNotMe() {
        XCTAssertEqual(OfferResponse(rawValue: "NOT_ME"), .notMe)
    }

    func testInitFromAbandoned() {
        XCTAssertEqual(OfferResponse(rawValue: "ABANDONED"), .abandoned)
    }

    func testInitFromPrescreenNo() {
        XCTAssertEqual(OfferResponse(rawValue: "PRESCREEN_NO"), .prescreenNo)
    }

    // MARK: - Invalid Raw Values

    func testInitFromUnknownRawValue() {
        XCTAssertNil(OfferResponse(rawValue: "UNKNOWN"))
    }

    func testInitFromEmptyString() {
        XCTAssertNil(OfferResponse(rawValue: ""))
    }

    func testInitFromLowercaseRawValue() {
        XCTAssertNil(OfferResponse(rawValue: "yes"))
        XCTAssertNil(OfferResponse(rawValue: "no"))
        XCTAssertNil(OfferResponse(rawValue: "not_me"))
        XCTAssertNil(OfferResponse(rawValue: "abandoned"))
        XCTAssertNil(OfferResponse(rawValue: "prescreen_no"))
    }

    // MARK: - Equality

    func testCaseEquality() {
        XCTAssertEqual(OfferResponse.yes, OfferResponse.yes)
        XCTAssertEqual(OfferResponse.no, OfferResponse.no)
        XCTAssertEqual(OfferResponse.notMe, OfferResponse.notMe)
        XCTAssertEqual(OfferResponse.abandoned, OfferResponse.abandoned)
        XCTAssertEqual(OfferResponse.prescreenNo, OfferResponse.prescreenNo)
    }

    func testCaseInequality() {
        XCTAssertNotEqual(OfferResponse.yes, OfferResponse.no)
        XCTAssertNotEqual(OfferResponse.notMe, OfferResponse.abandoned)
        XCTAssertNotEqual(OfferResponse.prescreenNo, OfferResponse.yes)
    }

    // MARK: - All Cases Coverage

    func testAllCasesDistinct() {
        let allCases: [OfferResponse] = [.yes, .no, .notMe, .abandoned, .prescreenNo]
        let rawValues = allCases.map { $0.rawValue }
        let uniqueRawValues = Set(rawValues)
        XCTAssertEqual(uniqueRawValues.count, allCases.count)
    }
}
