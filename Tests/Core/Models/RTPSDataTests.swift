//------------------------------------------------------------------------------
//  File:          RTPSDataTests.swift
//  Author(s):     Bread Financial
//  Date:          02 September 2026
//
//  Descriptions:  Unit tests for RTPSData and related models.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import XCTest
@testable import BreadPartnersSDKCore

final class RTPSDataTests: XCTestCase {
    // MARK: - Initialization

    func testBasicInitialization() {
        let rtps = RTPSData()
        XCTAssertNil(rtps.financingType)
        XCTAssertNil(rtps.order)
        XCTAssertNil(rtps.locationType)
        XCTAssertNil(rtps.screenName)
        XCTAssertNil(rtps.cardType)
        XCTAssertNil(rtps.country)
        XCTAssertNil(rtps.prescreenId)
        XCTAssertNil(rtps.correlationData)
        XCTAssertNil(rtps.customerAcceptedOffer)
        XCTAssertNil(rtps.channel)
        XCTAssertNil(rtps.subChannel)
        XCTAssertNil(rtps.mockResponse)
    }

    func testInitializationWithValues() {
        let order = Order()
        let rtps = RTPSData(
            financingType: .card,
            order: order,
            locationType: .checkout,
            screenName: "checkout_screen",
            cardType: "VISA",
            country: "US",
            prescreenId: 9876543210,
            correlationData: "correlation123",
            customerAcceptedOffer: true,
            channel: "online",
            subChannel: "mobile",
            mockResponse: .success
        )

        XCTAssertEqual(rtps.financingType, .card)
        XCTAssertNotNil(rtps.order)
        XCTAssertEqual(rtps.locationType, .checkout)
        XCTAssertEqual(rtps.screenName, "checkout_screen")
        XCTAssertEqual(rtps.cardType, "VISA")
        XCTAssertEqual(rtps.country, "US")
        XCTAssertEqual(rtps.prescreenId, 9876543210)
        XCTAssertEqual(rtps.correlationData, "correlation123")
        XCTAssertTrue(rtps.customerAcceptedOffer ?? false)
        XCTAssertEqual(rtps.channel, "online")
        XCTAssertEqual(rtps.subChannel, "mobile")
        XCTAssertEqual(rtps.mockResponse, .success)
    }

    // MARK: - PrescreenId (Int64 Type)

    func testPrescreenIdInt64Type() {
        let rtps = RTPSData(prescreenId: 9223372036854775807)  // Max Int64
        XCTAssertEqual(rtps.prescreenId, 9223372036854775807)
    }

    func testPrescreenIdZero() {
        let rtps = RTPSData(prescreenId: 0)
        XCTAssertEqual(rtps.prescreenId, 0)
    }

    func testPrescreenIdNegative() {
        let rtps = RTPSData(prescreenId: -9876543210)
        XCTAssertEqual(rtps.prescreenId, -9876543210)
    }

    // MARK: - Correlation Data

    func testCorrelationData() {
        let correlationId = "correlation-abc-123-xyz"
        let rtps = RTPSData(correlationData: correlationId)
        XCTAssertEqual(rtps.correlationData, correlationId)
    }

    func testCorrelationDataEmpty() {
        let rtps = RTPSData(correlationData: "")
        XCTAssertEqual(rtps.correlationData, "")
    }

    // MARK: - Customer Accepted Offer

    func testCustomerAcceptedOfferTrue() {
        let rtps = RTPSData(customerAcceptedOffer: true)
        XCTAssertTrue(rtps.customerAcceptedOffer ?? false)
    }

    func testCustomerAcceptedOfferFalse() {
        let rtps = RTPSData(customerAcceptedOffer: false)
        XCTAssertFalse(rtps.customerAcceptedOffer ?? true)
    }

    // MARK: - Mock Options (All 9 Cases)

    func testMockOptionNoMock() {
        XCTAssertEqual(BreadPartnersMockOptions.noMock.rawValue, "")
    }

    func testMockOptionSuccess() {
        XCTAssertEqual(BreadPartnersMockOptions.success.rawValue, "success")
    }

    func testMockOptionNoHit() {
        XCTAssertEqual(BreadPartnersMockOptions.noHit.rawValue, "noHit")
    }

    func testMockOptionMakeOffer() {
        XCTAssertEqual(BreadPartnersMockOptions.makeOffer.rawValue, "makeOffer")
    }

    func testMockOptionAckknowledge() {
        XCTAssertEqual(BreadPartnersMockOptions.ackknowledge.rawValue, "ackknowledge")
    }

    func testMockOptionExistingAccount() {
        XCTAssertEqual(BreadPartnersMockOptions.existingAccount.rawValue, "existingAccount")
    }

    func testMockOptionExistingOffer() {
        XCTAssertEqual(BreadPartnersMockOptions.existingOffer.rawValue, "existingOffer")
    }

    func testMockOptionNewOffer() {
        XCTAssertEqual(BreadPartnersMockOptions.newOffer.rawValue, "newOffer")
    }

    func testMockOptionError() {
        XCTAssertEqual(BreadPartnersMockOptions.error.rawValue, "error")
    }

    func testAllMockOptionsCount() {
        let allOptions = BreadPartnersMockOptions.allCases
        XCTAssertEqual(allOptions.count, 9)
    }

    func testAllMockOptionsContents() {
        let allOptions = BreadPartnersMockOptions.allCases
        XCTAssertTrue(allOptions.contains(.noMock))
        XCTAssertTrue(allOptions.contains(.success))
        XCTAssertTrue(allOptions.contains(.noHit))
        XCTAssertTrue(allOptions.contains(.makeOffer))
        XCTAssertTrue(allOptions.contains(.ackknowledge))
        XCTAssertTrue(allOptions.contains(.existingAccount))
        XCTAssertTrue(allOptions.contains(.existingOffer))
        XCTAssertTrue(allOptions.contains(.newOffer))
        XCTAssertTrue(allOptions.contains(.error))
    }

    func testMockOptionsDistinct() {
        let allOptions = BreadPartnersMockOptions.allCases
        let rawValues = allOptions.map { $0.rawValue }
        let uniqueRawValues = Set(rawValues)
        XCTAssertEqual(uniqueRawValues.count, allOptions.count)
    }

    // MARK: - Financing Type with RTPS

    func testFinancingTypeCard() {
        let rtps = RTPSData(financingType: .card)
        XCTAssertEqual(rtps.financingType, .card)
    }

    func testFinancingTypeInstallments() {
        let rtps = RTPSData(financingType: .installments)
        XCTAssertEqual(rtps.financingType, .installments)
    }

    func testFinancingTypeVersatile() {
        let rtps = RTPSData(financingType: .versatile)
        XCTAssertEqual(rtps.financingType, .versatile)
    }

    // MARK: - Location Type with RTPS

    func testLocationTypeCheckout() {
        let rtps = RTPSData(locationType: .checkout)
        XCTAssertEqual(rtps.locationType, .checkout)
    }

    func testLocationTypeCart() {
        let rtps = RTPSData(locationType: .cart)
        XCTAssertEqual(rtps.locationType, .cart)
    }

    // MARK: - Channel and SubChannel

    func testChannelAndSubChannel() {
        let rtps = RTPSData(
            channel: "ecommerce",
            subChannel: "mobile_web"
        )
        XCTAssertEqual(rtps.channel, "ecommerce")
        XCTAssertEqual(rtps.subChannel, "mobile_web")
    }

    // MARK: - Card Type and Country

    func testCardTypeAndCountry() {
        let rtps = RTPSData(
            cardType: "MASTERCARD",
            country: "CA"
        )
        XCTAssertEqual(rtps.cardType, "MASTERCARD")
        XCTAssertEqual(rtps.country, "CA")
    }

    func testMultipleCardTypes() {
        let visaRtps = RTPSData(cardType: "VISA")
        let mastercardRtps = RTPSData(cardType: "MASTERCARD")
        let amexRtps = RTPSData(cardType: "AMEX")

        XCTAssertEqual(visaRtps.cardType, "VISA")
        XCTAssertEqual(mastercardRtps.cardType, "MASTERCARD")
        XCTAssertEqual(amexRtps.cardType, "AMEX")
    }

    func testMultipleCountries() {
        let usRtps = RTPSData(country: "US")
        let caRtps = RTPSData(country: "CA")
        let ukRtps = RTPSData(country: "UK")

        XCTAssertEqual(usRtps.country, "US")
        XCTAssertEqual(caRtps.country, "CA")
        XCTAssertEqual(ukRtps.country, "UK")
    }
}
