//------------------------------------------------------------------------------
//  File:          RTPSDataTests.swift
//  Author(s):     Bread Financial
//  Date:          02 September 2026
//
//  Descriptions:  Unit tests for RTPSData and related models.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Testing
@testable import BreadPartnersCore

@Suite struct RTPSDataTests {
    @Test
    func basicInitialization() {
        let rtps = RTPSData()
        #expect(rtps.financingType == nil)
        #expect(rtps.order == nil)
        #expect(rtps.locationType == nil)
        #expect(rtps.screenName == nil)
        #expect(rtps.cardType == nil)
        #expect(rtps.country == nil)
        #expect(rtps.prescreenId == nil)
        #expect(rtps.correlationData == nil)
        #expect(rtps.customerAcceptedOffer == nil)
        #expect(rtps.channel == nil)
        #expect(rtps.subChannel == nil)
        #expect(rtps.mockResponse == nil)
    }

    @Test
    func initializationWithValues() {
        let order = Order()
        let rtps = RTPSData(
            financingType: .card,
            order: order,
            locationType: .checkout,
            screenName: "checkout_screen",
            cardType: "VISA",
            country: "US",
            prescreenId: 9_876_543_210,
            correlationData: "correlation123",
            customerAcceptedOffer: true,
            channel: "online",
            subChannel: "mobile",
            mockResponse: .success
        )

        #expect(rtps.financingType == BreadPartnersFinancingType.card)
        #expect(rtps.order === order)
        #expect(rtps.locationType == BreadPartnersLocationType.checkout)
        #expect(rtps.screenName == "checkout_screen")
        #expect(rtps.cardType == "VISA")
        #expect(rtps.country == "US")
        #expect(rtps.prescreenId == 9_876_543_210)
        #expect(rtps.correlationData == "correlation123")
        #expect(rtps.customerAcceptedOffer == true)
        #expect(rtps.channel == "online")
        #expect(rtps.subChannel == "mobile")
        #expect(rtps.mockResponse == BreadPartnersMockOptions.success)
    }

    @Test(arguments: [Int64.max, 0, -9_876_543_210])
    func prescreenId(value: Int64) {
        let rtps = RTPSData(prescreenId: value)
        #expect(rtps.prescreenId == value)
    }

    @Test(arguments: ["correlation-abc-123-xyz", ""])
    func correlationData(value: String) {
        let rtps = RTPSData(correlationData: value)
        #expect(rtps.correlationData == value)
    }

    @Test(arguments: [true, false])
    func customerAcceptedOffer(value: Bool) {
        let rtps = RTPSData(customerAcceptedOffer: value)
        #expect(rtps.customerAcceptedOffer == value)
    }

    @Test(arguments: [
        (BreadPartnersMockOptions.noMock, ""),
        (BreadPartnersMockOptions.success, "success"),
        (BreadPartnersMockOptions.noHit, "noHit"),
        (BreadPartnersMockOptions.makeOffer, "makeOffer"),
        (BreadPartnersMockOptions.ackknowledge, "ackknowledge"),
        (BreadPartnersMockOptions.existingAccount, "existingAccount"),
        (BreadPartnersMockOptions.existingOffer, "existingOffer"),
        (BreadPartnersMockOptions.newOffer, "newOffer"),
        (BreadPartnersMockOptions.error, "error"),
    ])
    func mockOptionRawValue(option: BreadPartnersMockOptions, expectedRawValue: String) {
        #expect(option.rawValue == expectedRawValue)
    }

    @Test(arguments: [
        BreadPartnersFinancingType.card,
        BreadPartnersFinancingType.installments,
        BreadPartnersFinancingType.versatile,
    ])
    func financingType(financingType: BreadPartnersFinancingType) {
        let rtps = RTPSData(financingType: financingType)
        #expect(rtps.financingType == financingType)
    }

    @Test(arguments: [
        BreadPartnersLocationType.checkout,
        BreadPartnersLocationType.cart,
    ])
    func locationType(locationType: BreadPartnersLocationType) {
        let rtps = RTPSData(locationType: locationType)
        #expect(rtps.locationType == locationType)
    }

    @Test
    func channelAndSubChannel() {
        let rtps = RTPSData(channel: "ecommerce", subChannel: "mobile_web")
        #expect(rtps.channel == "ecommerce")
        #expect(rtps.subChannel == "mobile_web")
    }

    @Test(arguments: ["VISA", "MASTERCARD", "AMEX"])
    func cardType(cardType: String) {
        let rtps = RTPSData(cardType: cardType)
        #expect(rtps.cardType == cardType)
    }

    @Test(arguments: ["US", "CA", "UK"])
    func country(country: String) {
        let rtps = RTPSData(country: country)
        #expect(rtps.country == country)
    }

}
