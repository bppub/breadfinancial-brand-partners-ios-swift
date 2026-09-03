//------------------------------------------------------------------------------
//  File:          MerchantConfigurationTests.swift
//  Author(s):     Bread Financial
//  Date:          02 September 2026
//
//  Descriptions:  Unit tests for MerchantConfiguration.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Foundation
import Testing
@testable import BreadPartnersCore

@Suite struct MerchantConfigurationTests {
    // MARK: - Store Number Handling

    @Test
    func testMerchantConfigurationDefaultStore() {
        let config = MerchantConfiguration()
        #expect(config.storeNumber == "8883")
    }

    @Test
    func testMerchantConfigurationStoreNumberDefault() {
        let config = MerchantConfiguration(storeNumber: "")
        #expect(config.storeNumber == "8883")
    }

    @Test
    func testMerchantConfigurationStoreNumberPreserved() {
        let config = MerchantConfiguration(storeNumber: "1234")
        #expect(config.storeNumber == "1234")
    }

    // MARK: - Payment Mode

    @Test
    func testPaymentModeRawValues() {
        #expect(MerchantConfiguration.PaymentMode.full.rawValue == "full")
        #expect(MerchantConfiguration.PaymentMode.split.rawValue == "split")
    }

    @Test
    func testPaymentModeInitialization() {
        let fullMode = MerchantConfiguration.PaymentMode(rawValue: "full")
        let splitMode = MerchantConfiguration.PaymentMode(rawValue: "split")
        #expect(fullMode == .full)
        #expect(splitMode == .split)
    }

    // MARK: - Buyer Initialization

    @Test
    func testBuyerInitialization() {
        let buyer = BreadPartnersBuyer(givenName: "Jane")
        let config = MerchantConfiguration(buyer: buyer)
        #expect(config.buyer?.givenName == "Jane")
    }

    @Test
    func testAddressInitialization() {
        let address = BreadPartnersAddress(
            address1: "123 Main Street",
            address2: "Apt 4B",
            country: "US",
            locality: "Columbus",
            region: "OH",
            postalCode: "43215"
        )

        #expect(address.address1 == "123 Main Street")
        #expect(address.address2 == "Apt 4B")
        #expect(address.country == "US")
        #expect(address.locality == "Columbus")
        #expect(address.region == "OH")
        #expect(address.postalCode == "43215")
    }

    // MARK: - Custom Dictionary

    @Test
    func testCustomDictionary() {
        let customData: [String: Any] = [
            "key1": "value1",
            "key2": 42,
            "key3": true,
        ]
        let config = MerchantConfiguration(custom: customData)
        #expect(config.custom?.count == 3)
        #expect(config.custom?["key1"] as? String == "value1")
        #expect(config.custom?["key2"] as? Int == 42)
        #expect(config.custom?["key3"] as? Bool == true)
    }

    // MARK: - All Properties Initialization

    @Test
    func testAllPropertiesInitialization() {
        let buyer = BreadPartnersBuyer(givenName: "Jane")
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

        #expect(config.buyer?.givenName == "Jane")
        #expect(config.loyaltyID == "loyalty123")
        #expect(config.campaignID == "campaign456")
        #expect(config.storeNumber == "5678")
        #expect(config.departmentId == "dept789")
        #expect(config.existingCardHolder == true)
        #expect(config.cardholderTier == "gold")
        #expect(config.env == BreadPartnersEnvironment.uat)
        #expect(config.cardEnv == "card_env")
        #expect(config.channel == "online")
        #expect(config.subchannel == "mobile")
        #expect(config.clerkId == "clerk001")
        #expect(config.overrideKey == "override123")
        #expect(config.clientVariable1 == "var1")
        #expect(config.clientVariable2 == "var2")
        #expect(config.clientVariable3 == "var3")
        #expect(config.clientVariable4 == "var4")
        #expect(config.accountId == "account001")
        #expect(config.applicationId == "app001")
        #expect(config.invoiceNumber == "inv001")
        #expect(config.paymentMode == MerchantConfiguration.PaymentMode.split)
        #expect(config.providerConfig == providerConfig)
        #expect(config.skipVerification == true)
        #expect((config.custom?["test"] as? String) == "data")
        #expect(config.cardChoiceCode == "choice123")
    }

    // MARK: - Nil Properties

    @Test
    func testNilProperties() {
        let config = MerchantConfiguration()
        #expect(config.buyer == nil)
        #expect(config.loyaltyID == nil)
        #expect(config.campaignID == nil)
        #expect(config.departmentId == nil)
        #expect(config.existingCardHolder == nil)
        #expect(config.cardholderTier == nil)
        #expect(config.env == nil)
        #expect(config.cardEnv == nil)
        #expect(config.channel == nil)
        #expect(config.subchannel == nil)
        #expect(config.clerkId == nil)
        #expect(config.overrideKey == nil)
        #expect(config.paymentMode == nil)
        #expect(config.providerConfig == nil)
        #expect(config.skipVerification == nil)
        #expect(config.custom == nil)
    }
}
