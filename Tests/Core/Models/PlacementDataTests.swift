//------------------------------------------------------------------------------
//  File:          PlacementDataTests.swift
//  Author(s):     Bread Financial
//  Date:          02 September 2026
//
//  Descriptions:  Unit tests for PlacementData and related models.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import XCTest
@testable import BreadPartnersSDKCore

final class PlacementDataTests: XCTestCase {
    // MARK: - Initialization

    func testBasicInitialization() {
        let placement = PlacementData()
        XCTAssertNil(placement.financingType)
        XCTAssertNil(placement.locationType)
        XCTAssertNil(placement.placementId)
        XCTAssertNil(placement.domID)
        XCTAssertNil(placement.allowCheckout)
        XCTAssertNil(placement.order)
    }

    func testInitializationWithValues() {
        let order = Order()
        let placement = PlacementData(
            financingType: .installments,
            locationType: .checkout,
            placementId: "placement123",
            domID: "dom456",
            allowCheckout: true,
            order: order
        )

        XCTAssertEqual(placement.financingType, .installments)
        XCTAssertEqual(placement.locationType, .checkout)
        XCTAssertEqual(placement.placementId, "placement123")
        XCTAssertEqual(placement.domID, "dom456")
        XCTAssertTrue(placement.allowCheckout ?? false)
        XCTAssertNotNil(placement.order)
    }

    // MARK: - Financing Type Mapping

    func testFinancingTypeCard() {
        let placement = PlacementData(financingType: .card)
        XCTAssertEqual(placement.financingType, .card)
        XCTAssertEqual(placement.financingType?.rawValue, "card")
    }

    func testFinancingTypeInstallments() {
        let placement = PlacementData(financingType: .installments)
        XCTAssertEqual(placement.financingType, .installments)
        XCTAssertEqual(placement.financingType?.rawValue, "installments")
    }

    func testFinancingTypeVersatile() {
        let placement = PlacementData(financingType: .versatile)
        XCTAssertEqual(placement.financingType, .versatile)
        XCTAssertEqual(placement.financingType?.rawValue, "versatile")
    }

    func testAllFinancingTypes() {
        let allTypes = BreadPartnersFinancingType.allCases
        XCTAssertEqual(allTypes.count, 3)
        XCTAssertTrue(allTypes.contains(.card))
        XCTAssertTrue(allTypes.contains(.installments))
        XCTAssertTrue(allTypes.contains(.versatile))
    }

    // MARK: - Location Type Channel Code Mapping (All 15 Cases)

    func testLocationTypeHomepage() {
        let placement = PlacementData(locationType: .homepage)
        XCTAssertEqual(placement.locationType, .homepage)
        XCTAssertEqual(placement.locationType?.channelCode, "H")
    }

    func testLocationTypeLanding() {
        let placement = PlacementData(locationType: .landing)
        XCTAssertEqual(placement.locationType, .landing)
        XCTAssertEqual(placement.locationType?.channelCode, "L")
    }

    func testLocationTypeSearch() {
        let placement = PlacementData(locationType: .search)
        XCTAssertEqual(placement.locationType, .search)
        XCTAssertEqual(placement.locationType?.channelCode, "S")
    }

    func testLocationTypeProduct() {
        let placement = PlacementData(locationType: .product)
        XCTAssertEqual(placement.locationType, .product)
        XCTAssertEqual(placement.locationType?.channelCode, "P")
    }

    func testLocationTypeCategory() {
        let placement = PlacementData(locationType: .category)
        XCTAssertEqual(placement.locationType, .category)
        XCTAssertEqual(placement.locationType?.channelCode, "C")
    }

    func testLocationTypeBanner() {
        let placement = PlacementData(locationType: .banner)
        XCTAssertEqual(placement.locationType, .banner)
        XCTAssertEqual(placement.locationType?.channelCode, "U")
    }

    func testLocationTypeCheckout() {
        let placement = PlacementData(locationType: .checkout)
        XCTAssertEqual(placement.locationType, .checkout)
        XCTAssertEqual(placement.locationType?.channelCode, "O")
    }

    func testLocationTypeCart() {
        let placement = PlacementData(locationType: .cart)
        XCTAssertEqual(placement.locationType, .cart)
        XCTAssertEqual(placement.locationType?.channelCode, "A")
    }

    func testLocationTypeMobile() {
        let placement = PlacementData(locationType: .mobile)
        XCTAssertEqual(placement.locationType, .mobile)
        XCTAssertEqual(placement.locationType?.channelCode, "E")
    }

    func testLocationTypeLoyalty() {
        let placement = PlacementData(locationType: .loyalty)
        XCTAssertEqual(placement.locationType, .loyalty)
        XCTAssertEqual(placement.locationType?.channelCode, "D")
    }

    func testLocationTypeFooter() {
        let placement = PlacementData(locationType: .footer)
        XCTAssertEqual(placement.locationType, .footer)
        XCTAssertEqual(placement.locationType?.channelCode, "F")
    }

    func testLocationTypeBag() {
        let placement = PlacementData(locationType: .bag)
        XCTAssertEqual(placement.locationType, .bag)
        XCTAssertEqual(placement.locationType?.channelCode, "2")
    }

    func testLocationTypeDashboard() {
        let placement = PlacementData(locationType: .dashboard)
        XCTAssertEqual(placement.locationType, .dashboard)
        XCTAssertEqual(placement.locationType?.channelCode, "5")
    }

    func testLocationTypeMyaccount() {
        let placement = PlacementData(locationType: .myaccount)
        XCTAssertEqual(placement.locationType, .myaccount)
        XCTAssertEqual(placement.locationType?.channelCode, "5")
    }

    func testLocationTypeHeader() {
        let placement = PlacementData(locationType: .header)
        XCTAssertEqual(placement.locationType, .header)
        XCTAssertEqual(placement.locationType?.channelCode, "R")
    }

    func testAllLocationTypes() {
        let allTypes = BreadPartnersLocationType.allCases
        XCTAssertEqual(allTypes.count, 15)
        XCTAssertTrue(allTypes.contains(.homepage))
        XCTAssertTrue(allTypes.contains(.landing))
        XCTAssertTrue(allTypes.contains(.search))
        XCTAssertTrue(allTypes.contains(.product))
        XCTAssertTrue(allTypes.contains(.category))
        XCTAssertTrue(allTypes.contains(.banner))
        XCTAssertTrue(allTypes.contains(.checkout))
        XCTAssertTrue(allTypes.contains(.cart))
        XCTAssertTrue(allTypes.contains(.mobile))
        XCTAssertTrue(allTypes.contains(.loyalty))
        XCTAssertTrue(allTypes.contains(.footer))
        XCTAssertTrue(allTypes.contains(.bag))
        XCTAssertTrue(allTypes.contains(.dashboard))
        XCTAssertTrue(allTypes.contains(.myaccount))
        XCTAssertTrue(allTypes.contains(.header))
    }

    func testLocationChannelMapCompleteness() {
        let locationMap = BreadPartnersLocationType.locationChannelMap
        XCTAssertEqual(locationMap.count, 15)

        for locationType in BreadPartnersLocationType.allCases {
            XCTAssertNotNil(locationMap[locationType], "Missing channel code for \(locationType)")
        }
    }

    // MARK: - Known Bug: prequalificationId and prequalCreditLimit Assignment

    func testPrequalificationIdAssignment() {
        // Bug: Both prequalificationId and prequalCreditLimit are assigned from financingBuyerId
        let placement = PlacementData(
            financingBuyerId: "buyer123",
            prequalificationId: nil,  // This parameter is not used in the initializer
            prequalCreditLimit: nil  // This parameter is not used in the initializer
        )

        // Current behavior (expected to fail when bug is fixed):
        XCTAssertEqual(placement.financingBuyerId, "buyer123")
        XCTAssertEqual(
            placement.prequalificationId, "buyer123",
            "Bug: prequalificationId should use its own parameter, not financingBuyerId")
        XCTAssertEqual(
            placement.prequalCreditLimit, "buyer123",
            "Bug: prequalCreditLimit should use its own parameter, not financingBuyerId")
    }
}

// MARK: - Order Tests

final class OrderTests: XCTestCase {
    func testOrderBasicInitialization() {
        let order = Order()
        XCTAssertNil(order.subTotal)
        XCTAssertNil(order.totalDiscounts)
        XCTAssertNil(order.totalPrice)
        XCTAssertNil(order.totalShipping)
        XCTAssertNil(order.totalTax)
    }

    func testOrderInitializationWithValues() {
        let subTotal = CurrencyValue(value: 100.00, currency: "USD")
        let totalDiscounts = CurrencyValue(value: 10.00, currency: "USD")
        let totalPrice = CurrencyValue(value: 90.00, currency: "USD")
        let totalShipping = CurrencyValue(value: 5.00, currency: "USD")
        let totalTax = CurrencyValue(value: 7.20, currency: "USD")

        let order = Order(
            subTotal: subTotal,
            totalDiscounts: totalDiscounts,
            totalPrice: totalPrice,
            totalShipping: totalShipping,
            totalTax: totalTax,
            discountCode: "SAVE10",
            bnplEligible: true
        )

        XCTAssertNotNil(order.subTotal)
        XCTAssertEqual(order.subTotal?.value, 100.00)
        XCTAssertEqual(order.subTotal?.currency, "USD")

        XCTAssertNotNil(order.totalDiscounts)
        XCTAssertEqual(order.totalDiscounts?.value, 10.00)

        XCTAssertNotNil(order.totalPrice)
        XCTAssertEqual(order.totalPrice?.value, 90.00)

        XCTAssertNotNil(order.totalShipping)
        XCTAssertEqual(order.totalShipping?.value, 5.00)

        XCTAssertNotNil(order.totalTax)
        XCTAssertEqual(order.totalTax?.value, 7.20)

        XCTAssertEqual(order.discountCode, "SAVE10")
        XCTAssertTrue(order.bnplEligible ?? false)
    }

    func testOrderCurrencyTypes() {
        let usdValue = CurrencyValue(value: 100.00, currency: "USD")
        let eurValue = CurrencyValue(value: 85.00, currency: "EUR")
        let gbpValue = CurrencyValue(value: 75.00, currency: "GBP")

        let order = Order(
            subTotal: usdValue,
            totalPrice: eurValue,
            totalTax: gbpValue
        )

        XCTAssertEqual(order.subTotal?.currency, "USD")
        XCTAssertEqual(order.totalPrice?.currency, "EUR")
        XCTAssertEqual(order.totalTax?.currency, "GBP")
    }
}
