//------------------------------------------------------------------------------
//  File:          PlacementDataTests.swift
//  Author(s):     Bread Financial
//  Date:          02 September 2026
//
//  Descriptions:  Unit tests for PlacementData and related types.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import XCTest
@testable import BreadPartnersSDKCore

final class PlacementDataTests: XCTestCase {
    func testPlacementDataInitialization() {
        let placement = PlacementData()
        XCTAssertNil(placement.financingType)
        XCTAssertNil(placement.locationType)
        XCTAssertNil(placement.placementId)
    }

    func testLocationTypeChannelMapping() {
        XCTAssertEqual(BreadPartnersLocationType.homepage.channelCode, "H")
        XCTAssertEqual(BreadPartnersLocationType.product.channelCode, "P")
        XCTAssertEqual(BreadPartnersLocationType.checkout.channelCode, "O")
    }

    func testFinancingTypeValues() {
        XCTAssertEqual(BreadPartnersFinancingType.card.rawValue, "card")
        XCTAssertEqual(BreadPartnersFinancingType.installments.rawValue, "installments")
        XCTAssertEqual(BreadPartnersFinancingType.versatile.rawValue, "versatile")
    }
}
