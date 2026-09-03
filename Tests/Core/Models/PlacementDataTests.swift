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
@testable import BreadPartnersCore

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
    func locationChannelMapCompleteness() {
        let locationMap = BreadPartnersLocationType.locationChannelMap
        #expect(locationMap.count == 15)

        for locationType in BreadPartnersLocationType.allCases {
            #expect(locationMap[locationType] != nil, "Missing channel code for \(locationType)")
        }
    }

    @Test
    func financingBuyerIdPopulatesPrequalificationFields() {
        let placement = PlacementData(
            defaultSelectedCardKey: "default-card",
            selectedCardKey: "selected-card",
            upqInSessionToken: "session-token",
            financingBuyerId: "buyer-id",
            prequalificationId: "prequalification-id",
            prequalCreditLimit: "5000"
        )

        #expect(placement.defaultSelectedCardKey == "default-card")
        #expect(placement.selectedCardKey == "selected-card")
        #expect(placement.upqInSessionToken == "session-token")
        #expect(placement.financingBuyerId == "buyer-id")
        #expect(placement.prequalificationId == "buyer-id")
        #expect(placement.prequalCreditLimit == "buyer-id")
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

    @Test
    func fulfillmentModelsInitialization() {
        let name = Name(
            givenName: "Jane",
            familyName: "Doe",
            additionalName: "Q"
        )
        let address = Address(
            address1: "123 Main Street",
            address2: "Apt 4B",
            locality: "Columbus",
            postalCode: "43215",
            region: "OH",
            country: "US"
        )
        let pickupInformation = PickupInformation(
            name: name,
            phone: "555-0100",
            address: address,
            email: "jane@example.com"
        )

        #expect(pickupInformation.name?.givenName == "Jane")
        #expect(pickupInformation.name?.familyName == "Doe")
        #expect(pickupInformation.name?.additionalName == "Q")
        #expect(pickupInformation.phone == "555-0100")
        #expect(pickupInformation.address?.address1 == "123 Main Street")
        #expect(pickupInformation.address?.address2 == "Apt 4B")
        #expect(pickupInformation.address?.locality == "Columbus")
        #expect(pickupInformation.address?.postalCode == "43215")
        #expect(pickupInformation.address?.region == "OH")
        #expect(pickupInformation.address?.country == "US")
        #expect(pickupInformation.email == "jane@example.com")
    }

    @Test
    func itemInitialization() {
        let unitPrice = CurrencyValue(currency: "USD", value: 1_000)
        let unitTax = CurrencyValue(currency: "USD", value: 80)
        let shippingCost = CurrencyValue(currency: "USD", value: 100)
        let item = Item(
            name: "Shoes",
            category: "apparel",
            quantity: 2,
            unitPrice: unitPrice,
            unitTax: unitTax,
            sku: "SKU-123",
            itemUrl: "https://example.com/shoes",
            imageUrl: "https://example.com/shoes.jpg",
            description: "Running shoes",
            shippingCost: shippingCost,
            shippingProvider: "Carrier",
            shippingDescription: "Standard",
            shippingTrackingNumber: "TRACK-123",
            shippingTrackingUrl: "https://example.com/tracking/TRACK-123",
            fulfillmentType: .delivery
        )

        #expect(item.name == "Shoes")
        #expect(item.category == "apparel")
        #expect(item.quantity == 2)
        #expect(item.unitPrice === unitPrice)
        #expect(item.unitTax === unitTax)
        #expect(item.sku == "SKU-123")
        #expect(item.itemUrl == "https://example.com/shoes")
        #expect(item.imageUrl == "https://example.com/shoes.jpg")
        #expect(item.description == "Running shoes")
        #expect(item.shippingCost === shippingCost)
        #expect(item.shippingProvider == "Carrier")
        #expect(item.shippingDescription == "Standard")
        #expect(item.shippingTrackingNumber == "TRACK-123")
        #expect(item.shippingTrackingUrl == "https://example.com/tracking/TRACK-123")
        #expect(item.fulfillmentType == .delivery)
    }
}
