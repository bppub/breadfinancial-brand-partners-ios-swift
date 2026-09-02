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
    // MARK: - Store Number Handling

    func testMerchantConfigurationDefaultStore() {
        let config = MerchantConfiguration()
        XCTAssertEqual(config.storeNumber, "8883")
    }

    func testMerchantConfigurationStoreNumberDefault() {
        let config = MerchantConfiguration(storeNumber: "")
        XCTAssertEqual(config.storeNumber, "8883")
    }

    func testMerchantConfigurationStoreNumberPreserved() {
        let config = MerchantConfiguration(storeNumber: "1234")
        XCTAssertEqual(config.storeNumber, "1234")
    }

    // MARK: - Payment Mode

    func testPaymentModeRawValues() {
        XCTAssertEqual(MerchantConfiguration.PaymentMode.full.rawValue, "full")
        XCTAssertEqual(MerchantConfiguration.PaymentMode.split.rawValue, "split")
    }

    func testPaymentModeInitialization() {
        let fullMode = MerchantConfiguration.PaymentMode(rawValue: "full")
        let splitMode = MerchantConfiguration.PaymentMode(rawValue: "split")
        XCTAssertEqual(fullMode, .full)
        XCTAssertEqual(splitMode, .split)
    }

    // MARK: - Buyer Initialization

    func testBuyerInitialization() {
        let buyer = BreadPartnersBuyer()
        let config = MerchantConfiguration(buyer: buyer)
        XCTAssertNotNil(config.buyer)
        XCTAssert(config.buyer === buyer)
    }

    // MARK: - Environment Property

    func testEnvironmentProperty() {
        let config = MerchantConfiguration(env: .stage)
        XCTAssertEqual(config.env, .stage)

        let configProd = MerchantConfiguration(env: .prod)
        XCTAssertEqual(configProd.env, .prod)

        let configNil = MerchantConfiguration(env: nil)
        XCTAssertNil(configNil.env)
    }

    // MARK: - Custom Dictionary

    func testCustomDictionary() {
        let customData: [String: Any] = [
            "key1": "value1",
            "key2": 42,
            "key3": true,
        ]
        let config = MerchantConfiguration(custom: customData)
        XCTAssertNotNil(config.custom)
        XCTAssertEqual(config.custom?.count, 3)
        XCTAssertEqual(config.custom?["key1"] as? String, "value1")
        XCTAssertEqual(config.custom?["key2"] as? Int, 42)
        XCTAssertEqual(config.custom?["key3"] as? Bool, true)
    }

    // MARK: - All Properties Initialization

    func testAllPropertiesInitialization() {
        let buyer = BreadPartnersBuyer()
        let customData: [String: Any] = ["test": "data"]
        let providerConfig: [String: Data] = ["provider": Data()]

        let config = MerchantConfiguration(
            buyer: buyer,
            loyaltyID: "loyalty123",
            campaignID: "campaign456",
            storeNumber: "5678",
            departmentId: "dept789",
            existingCardHolder: true,
            cardholderTier: "gold",
            env: .uat,
            cardEnv: "card_env",
            channel: "online",
            subchannel: "mobile",
            clerkId: "clerk001",
            overrideKey: "override123",
            clientVariable1: "var1",
            clientVariable2: "var2",
            clientVariable3: "var3",
            clientVariable4: "var4",
            accountId: "account001",
            applicationId: "app001",
            invoiceNumber: "inv001",
            paymentMode: .split,
            providerConfig: providerConfig,
            skipVerification: true,
            custom: customData,
            cardChoiceCode: "choice123"
        )

        XCTAssertNotNil(config.buyer)
        XCTAssertEqual(config.loyaltyID, "loyalty123")
        XCTAssertEqual(config.campaignID, "campaign456")
        XCTAssertEqual(config.storeNumber, "5678")
        XCTAssertEqual(config.departmentId, "dept789")
        XCTAssertTrue(config.existingCardHolder ?? false)
        XCTAssertEqual(config.cardholderTier, "gold")
        XCTAssertEqual(config.env, .uat)
        XCTAssertEqual(config.cardEnv, "card_env")
        XCTAssertEqual(config.channel, "online")
        XCTAssertEqual(config.subchannel, "mobile")
        XCTAssertEqual(config.clerkId, "clerk001")
        XCTAssertEqual(config.overrideKey, "override123")
        XCTAssertEqual(config.clientVariable1, "var1")
        XCTAssertEqual(config.clientVariable2, "var2")
        XCTAssertEqual(config.clientVariable3, "var3")
        XCTAssertEqual(config.clientVariable4, "var4")
        XCTAssertEqual(config.accountId, "account001")
        XCTAssertEqual(config.applicationId, "app001")
        XCTAssertEqual(config.invoiceNumber, "inv001")
        XCTAssertEqual(config.paymentMode, .split)
        XCTAssertNotNil(config.providerConfig)
        XCTAssertTrue(config.skipVerification ?? false)
        XCTAssertNotNil(config.custom)
        XCTAssertEqual(config.cardChoiceCode, "choice123")
    }

    // MARK: - Nil Properties

    func testNilProperties() {
        let config = MerchantConfiguration()
        XCTAssertNil(config.buyer)
        XCTAssertNil(config.loyaltyID)
        XCTAssertNil(config.campaignID)
        XCTAssertNil(config.departmentId)
        XCTAssertNil(config.existingCardHolder)
        XCTAssertNil(config.cardholderTier)
        XCTAssertNil(config.env)
        XCTAssertNil(config.cardEnv)
        XCTAssertNil(config.channel)
        XCTAssertNil(config.subchannel)
        XCTAssertNil(config.clerkId)
        XCTAssertNil(config.overrideKey)
        XCTAssertNil(config.paymentMode)
        XCTAssertNil(config.providerConfig)
        XCTAssertNil(config.skipVerification)
        XCTAssertNil(config.custom)
    }
}
