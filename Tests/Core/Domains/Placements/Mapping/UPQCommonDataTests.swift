//------------------------------------------------------------------------------
//  File:          UPQCommonDataTests.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import BreadPartnersCore
import Foundation
import Testing

@Suite struct UPQCommonDataTests {
    private let mapper = UPQMapper()

    @Test
    func mapsBuyerBillingAddressMerchantAndPlacementFields() throws {
        let buyer = BreadPartnersBuyer(
            givenName: "Ada", familyName: "Lovelace", additionalName: "ignored", birthDate: "ignored",
            email: "ada@example.com", phone: "123", alternativePhone: "456",
            billingAddress: BreadPartnersAddress(
                address1: "Billing Street", address2: "Suite 1", country: "ignored-country",
                locality: "Columbus", region: "OH", postalCode: "43004"
            ),
            shippingAddress: BreadPartnersAddress(address1: "Not Billing Street")
        )
        let merchant = MerchantConfiguration(
            buyer: buyer, loyaltyID: "loyalty", campaignID: "ignored", storeNumber: "12",
            departmentId: "department", existingCardHolder: true, cardholderTier: "ignored",
            channel: "merchant-channel", subchannel: "merchant-subchannel", clerkId: "associate",
            overrideKey: "override", clientVariable1: "one", clientVariable2: "two",
            clientVariable3: "three", clientVariable4: "four", paymentMode: .split, cardChoiceCode: "choice"
        )
        let placement = PlacementData(
            locationType: .checkout, placementId: "placement", order: Order(totalPrice: CurrencyValue(value: 12345)),
            defaultSelectedCardKey: "default-card", selectedCardKey: "selected-card"
        )
        let data = mapper.mapCommonData(
            placementData: placement, merchantConfiguration: merchant, sessionId: "session", userTrackingId: "tracking"
        )
        let expected: [String: Any] = [
            "firstName": "Ada", "lastName": "Lovelace", "address1": "Billing Street", "address2": "Suite 1",
            "city": "Columbus", "state": "OH", "zip": "43004", "emailAddress": "ada@example.com",
            "mobilePhone": "123", "alternativePhone": "456", "storeNumber": "12", "loyaltyNumber": "loyalty",
            "departmentId": "department", "checkoutAmount": 123.45, "location": "checkout", "epId": "tracking",
            "epPlacementId": "placement", "epSessionId": "session", "channel": "merchant-channel",
            "subchannel": "merchant-subchannel", "clientVariable1": "one", "clientVariable2": "two",
            "clientVariable3": "three", "clientVariable4": "four", "selectedCardKey": "selected-card",
            "defaultSelectedCardKey": "default-card", "overrideKey": "override", "cardChoiceCode": "choice",
            "associateId": "associate", "splitPayment": true,
        ]
        #expect(try #require(unwrapForJSON(data) as? NSDictionary) == expected as NSDictionary)
    }

    @Test
    func absentConfigurationOmitsAllFieldsAndDoesNotInventChannelDefaults() {
        #expect(mapper.mapCommonData().isEmpty)
        let data = mapper.mapCommonData(
            placementData: PlacementData(locationType: .checkout), merchantConfiguration: MerchantConfiguration()
        )
        #expect(data["storeNumber"] as? String == "8883")
        #expect(data["location"] as? String == "checkout")
        #expect(data["channel"] == nil)
        #expect(data["subchannel"] == nil)
    }

    @Test
    func omitsEmptyStringsButRetainsWhitespaceAndZeroAmounts() {
        var merchant = MerchantConfiguration(
            buyer: BreadPartnersBuyer(
                givenName: "", familyName: " ", email: "", billingAddress: BreadPartnersAddress(address1: "")
            ),
            loyaltyID: "", departmentId: "", channel: "", clientVariable1: "", paymentMode: .full
        )
        merchant.storeNumber = nil
        let data = mapper.mapCommonData(
            placementData: PlacementData(placementId: "", order: Order(totalPrice: CurrencyValue(value: 0))),
            merchantConfiguration: merchant, sessionId: "", userTrackingId: ""
        )
        #expect(data.keys.sorted() == ["checkoutAmount", "lastName"])
        #expect(data["lastName"] as? String == " ")
        #expect(data["checkoutAmount"] as? Double == 0)
    }

    @Test(arguments: [MerchantConfiguration.PaymentMode.full, .split])
    func splitPaymentIsOnlyIncludedForSplitMode(mode: MerchantConfiguration.PaymentMode) {
        let data = mapper.mapCommonData(merchantConfiguration: MerchantConfiguration(paymentMode: mode))
        if mode == .split {
            #expect(data["splitPayment"] as? Bool == true)
        } else {
            #expect(data["splitPayment"] == nil)
        }
        #expect(mapper.mapCommonData(merchantConfiguration: MerchantConfiguration())["splitPayment"] == nil)
    }

    @Test
    func mapsOnlyShippingAddressAndOmitsCountry() throws {
        let buyer = BreadPartnersBuyer(
            billingAddress: BreadPartnersAddress(address1: "Billing"),
            shippingAddress: BreadPartnersAddress(
                address1: "Shipping", address2: "Suite 2", country: "US", locality: "Columbus", region: "OH",
                postalCode: "43004"
            )
        )
        let address = try #require(mapper.mapShippingAddress(buyer: buyer))
        #expect(
            try #require(unwrapForJSON(address) as? NSDictionary)
                == ["address1": "Shipping", "address2": "Suite 2", "city": "Columbus", "state": "OH", "zip": "43004"]
                as NSDictionary
        )
        #expect(mapper.mapShippingAddress(buyer: nil) == nil)
        #expect(mapper.mapShippingAddress(buyer: BreadPartnersBuyer(billingAddress: buyer.billingAddress)) == nil)
    }

    @Test
    func presentButEmptyShippingAddressRemainsAnEmptyObject() throws {
        let address = try #require(
            mapper.mapShippingAddress(buyer: BreadPartnersBuyer(shippingAddress: BreadPartnersAddress(address1: ""))))
        #expect(address.isEmpty)
    }
}
