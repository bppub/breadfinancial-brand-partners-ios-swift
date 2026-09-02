//------------------------------------------------------------------------------
//  File:          PlacementDataTests.swift
//  Author(s):     Bread Financial
//  Date:          02 September 2026
//
//  Descriptions:  Unit tests for PlacementData and related models.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Testing
@testable import BreadPartnersSDKCore

@Suite struct PlacementDataTests {
    @Test
    func basicInitialization() {
        let placement = PlacementData()
        #expect(placement.financingType == nil)
        #expect(placement.locationType == nil)
        #expect(placement.placementId == nil)
        #expect(placement.domID == nil)
        #expect(placement.allowCheckout == nil)
        #expect(placement.order == nil)
    }

    @Test
    func initializationWithValues() {
        let order = Order()
        let placement = PlacementData(
            financingType: .installments,
            locationType: .checkout,
            placementId: "placement123",
            domID: "dom456",
            allowCheckout: true,
            order: order
        )

        #expect(placement.financingType == BreadPartnersFinancingType.installments)
        #expect(placement.locationType == BreadPartnersLocationType.checkout)
        #expect(placement.placementId == "placement123")
        #expect(placement.domID == "dom456")
        #expect(placement.allowCheckout == true)
        #expect(placement.order === order)
    }

    @Test(arguments: [
        BreadPartnersFinancingType.card,
        BreadPartnersFinancingType.installments,
        BreadPartnersFinancingType.versatile,
    ])
    func financingTypeMapping(financingType: BreadPartnersFinancingType) {
        let placement = PlacementData(financingType: financingType)
        #expect(placement.financingType == financingType)
        #expect(placement.financingType?.rawValue == financingType.rawValue)
    }

    @Test
    func allFinancingTypes() {
        let allTypes = BreadPartnersFinancingType.allCases
        #expect(allTypes.count == 3)
        #expect(allTypes.contains(.card))
        #expect(allTypes.contains(.installments))
        #expect(allTypes.contains(.versatile))
    }

    @Test(arguments: [
        (BreadPartnersLocationType.homepage, "H"),
        (BreadPartnersLocationType.landing, "L"),
        (BreadPartnersLocationType.search, "S"),
        (BreadPartnersLocationType.product, "P"),
        (BreadPartnersLocationType.category, "C"),
        (BreadPartnersLocationType.banner, "U"),
        (BreadPartnersLocationType.checkout, "O"),
        (BreadPartnersLocationType.cart, "A"),
        (BreadPartnersLocationType.mobile, "E"),
        (BreadPartnersLocationType.loyalty, "D"),
        (BreadPartnersLocationType.footer, "F"),
        (BreadPartnersLocationType.bag, "2"),
        (BreadPartnersLocationType.dashboard, "5"),
        (BreadPartnersLocationType.myaccount, "5"),
        (BreadPartnersLocationType.header, "R"),
    ])
    func locationTypeChannelCode(
        locationType: BreadPartnersLocationType,
        expectedCode: String
    ) {
        let placement = PlacementData(locationType: locationType)
        #expect(placement.locationType == locationType)
        #expect(placement.locationType?.channelCode == expectedCode)
    }

    @Test
    func allLocationTypes() {
        let allTypes = BreadPartnersLocationType.allCases
        #expect(allTypes.count == 15)
        #expect(allTypes.contains(.homepage))
        #expect(allTypes.contains(.landing))
        #expect(allTypes.contains(.search))
        #expect(allTypes.contains(.product))
        #expect(allTypes.contains(.category))
        #expect(allTypes.contains(.banner))
        #expect(allTypes.contains(.checkout))
        #expect(allTypes.contains(.cart))
        #expect(allTypes.contains(.mobile))
        #expect(allTypes.contains(.loyalty))
        #expect(allTypes.contains(.footer))
        #expect(allTypes.contains(.bag))
        #expect(allTypes.contains(.dashboard))
        #expect(allTypes.contains(.myaccount))
        #expect(allTypes.contains(.header))
    }

    @Test
    func locationChannelMapCompleteness() {
        let locationMap = BreadPartnersLocationType.locationChannelMap
        #expect(locationMap.count == 15)

        for locationType in BreadPartnersLocationType.allCases {
            #expect(locationMap[locationType] != nil, "Missing channel code for \(locationType)")
        }
    }

    @Test
    func prequalificationIdAssignment() {
        // Bug: Both prequalificationId and prequalCreditLimit are assigned from financingBuyerId
        let placement = PlacementData(
            financingBuyerId: "buyer123",
            prequalificationId: nil,
            prequalCreditLimit: nil
        )

        // Current behavior (expected to fail when bug is fixed):
        #expect(placement.financingBuyerId == "buyer123")
        #expect(
            placement.prequalificationId == "buyer123",
            "Bug: prequalificationId should use its own parameter, not financingBuyerId")
        #expect(
            placement.prequalCreditLimit == "buyer123",
            "Bug: prequalCreditLimit should use its own parameter, not financingBuyerId")
    }
}

@Suite struct OrderTests {
    @Test
    func basicInitialization() {
        let order = Order()
        #expect(order.subTotal == nil)
        #expect(order.totalDiscounts == nil)
        #expect(order.totalPrice == nil)
        #expect(order.totalShipping == nil)
        #expect(order.totalTax == nil)
    }

    @Test
    func initializationWithValues() {
        let subTotal = CurrencyValue(currency: "USD", value: 10_000)
        let totalDiscounts = CurrencyValue(currency: "USD", value: 1_000)
        let totalPrice = CurrencyValue(currency: "USD", value: 9_000)
        let totalShipping = CurrencyValue(currency: "USD", value: 500)
        let totalTax = CurrencyValue(currency: "USD", value: 720)

        let order = Order(
            subTotal: subTotal,
            totalDiscounts: totalDiscounts,
            totalPrice: totalPrice,
            totalShipping: totalShipping,
            totalTax: totalTax,
            discountCode: "SAVE10",
            bnplEligible: true
        )

        #expect(order.subTotal?.value == 10_000)
        #expect(order.subTotal?.currency == "USD")
        #expect(order.totalDiscounts?.value == 1_000)
        #expect(order.totalDiscounts?.currency == "USD")
        #expect(order.totalPrice?.value == 9_000)
        #expect(order.totalPrice?.currency == "USD")
        #expect(order.totalShipping?.value == 500)
        #expect(order.totalShipping?.currency == "USD")
        #expect(order.totalTax?.value == 720)
        #expect(order.totalTax?.currency == "USD")
        #expect(order.discountCode == "SAVE10")
        #expect(order.bnplEligible == true)
    }

    @Test
    func currencyTypes() {
        let order = Order(
            subTotal: CurrencyValue(currency: "USD", value: 10_000),
            totalPrice: CurrencyValue(currency: "EUR", value: 8_500),
            totalTax: CurrencyValue(currency: "GBP", value: 7_500)
        )

        #expect(order.subTotal?.currency == "USD")
        #expect(order.totalPrice?.currency == "EUR")
        #expect(order.totalTax?.currency == "GBP")
    }
}
