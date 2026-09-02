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
    func testOfferResponseValues() {
        XCTAssertEqual(OfferResponse.yes.rawValue, "YES")
        XCTAssertEqual(OfferResponse.no.rawValue, "NO")
        XCTAssertEqual(OfferResponse.notMe.rawValue, "NOT_ME")
        XCTAssertEqual(OfferResponse.abandoned.rawValue, "ABANDONED")
        XCTAssertEqual(OfferResponse.prescreenNo.rawValue, "PRESCREEN_NO")
    }

    func testOfferResponseInitialization() {
        XCTAssertEqual(OfferResponse(rawValue: "YES"), .yes)
        XCTAssertEqual(OfferResponse(rawValue: "NO"), .no)
        XCTAssertEqual(OfferResponse(rawValue: "INVALID"), nil)
    }
}
