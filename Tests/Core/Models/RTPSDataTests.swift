//------------------------------------------------------------------------------
//  File:          RTPSDataTests.swift
//  Author(s):     Bread Financial
//  Date:          02 September 2026
//
//  Descriptions:  Unit tests for RTPSData and related types.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import XCTest
@testable import BreadPartnersSDKCore

final class RTPSDataTests: XCTestCase {
    func testRTPSDataInitialization() {
        let rtps = RTPSData()
        XCTAssertNil(rtps.financingType)
        XCTAssertNil(rtps.order)
        XCTAssertNil(rtps.mockResponse)
    }

    func testBreadPartnersMockOptions() {
        XCTAssertEqual(BreadPartnersMockOptions.success.rawValue, "success")
        XCTAssertEqual(BreadPartnersMockOptions.error.rawValue, "error")
        XCTAssertEqual(BreadPartnersMockOptions.noMock.rawValue, "")
    }
}
