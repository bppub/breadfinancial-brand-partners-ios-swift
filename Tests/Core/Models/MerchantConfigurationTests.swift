//------------------------------------------------------------------------------
//  File:          MerchantConfigurationTests.swift
//  Author(s):     Bread Financial
//  Date:          02 September 2026
//
//  Descriptions:  Unit tests for MerchantConfiguration.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import XCTest
@testable import BreadPartnersSDKCore

final class MerchantConfigurationTests: XCTestCase {
    func testMerchantConfigurationDefaultStore() {
        let config = MerchantConfiguration()
        XCTAssertNil(config.storeNumber)
    }

    func testMerchantConfigurationStoreNumberDefault() {
        let config = MerchantConfiguration(storeNumber: "")
        XCTAssertEqual(config.storeNumber, "8883")
    }

    func testMerchantConfigurationStoreNumberPreserved() {
        let config = MerchantConfiguration(storeNumber: "1234")
        XCTAssertEqual(config.storeNumber, "1234")
    }

    func testMerchantConfigurationPaymentMode() {
        XCTAssertEqual(MerchantConfiguration.PaymentMode.full.rawValue, "full")
        XCTAssertEqual(MerchantConfiguration.PaymentMode.split.rawValue, "split")
    }
}
