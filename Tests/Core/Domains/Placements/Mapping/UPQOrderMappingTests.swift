import BreadPartnersCore
import Foundation
import Testing

@Suite struct UPQOrderMappingTests {
    private let mapper = UPQMapper()

    @Test
    func mapsOrderItemsAndPickupWithExactKeysAndMoneyConversion() throws {
        let order = Order(
            subTotal: CurrencyValue(currency: "USD", value: 12345),
            totalDiscounts: CurrencyValue(value: -105), totalPrice: CurrencyValue(value: 12240),
            totalShipping: CurrencyValue(value: 0), totalTax: CurrencyValue(value: 301), discountCode: "ignored",
            pickupInformation: PickupInformation(
                name: Name(givenName: "Ada", familyName: "Lovelace", additionalName: "A"), phone: "123",
                address: Address(
                    address1: "Pickup Street", address2: "Unit 1", locality: "Columbus", postalCode: "43004",
                    region: "OH", country: "ignored"),
                email: "ada@example.com"
            ),
            fulfillmentType: .multiple,
            items: [
                Item(
                    name: "Chair", category: "Furniture", quantity: 2, unitPrice: CurrencyValue(value: 5001),
                    unitTax: CurrencyValue(value: 200), sku: "sku", itemUrl: "ignored", imageUrl: "ignored",
                    description: "ignored", shippingCost: CurrencyValue(value: 123), shippingProvider: "ignored",
                    shippingDescription: "ignored", shippingTrackingNumber: "ignored", shippingTrackingUrl: "ignored",
                    fulfillmentType: .delivery
                )
            ],
            bnplEligible: false
        )
        let expected: [String: Any] = [
            "bnplEligible": false, "subTotalValue": 123.45, "totalDiscountsValue": -1.05, "totalPriceValue": 122.4,
            "totalShippingValue": 0, "totalTaxValue": 3.01, "fulfillmentType": "MULTIPLE",
            "items": [
                [
                    "name": "Chair", "category": "Furniture", "quantity": 2, "unitPriceValue": 50.01,
                    "unitTaxValue": 2, "sku": "sku", "shippingCostValue": 1.23, "fulfillmentType": "DELIVERY",
                ]
            ],
            "pickupInformation": [
                "name": ["firstName": "Ada", "lastName": "Lovelace", "additionalName": "A"],
                "address": [
                    "address1": "Pickup Street", "address2": "Unit 1", "city": "Columbus", "state": "OH",
                    "zip": "43004",
                ],
                "mobilePhone": "123", "emailAddress": "ada@example.com",
            ],
        ]
        #expect(try #require(unwrapForJSON(mapper.mapOrder(order)) as? NSDictionary) == expected as NSDictionary)
    }

    @Test
    func absentOrderNilMoneyAndEmptyItemsAreOmitted() {
        #expect(mapper.mapOrder(nil).isEmpty)
        #expect(mapper.mapOrder(Order()).isEmpty)
        #expect(mapper.mapOrder(Order(totalPrice: CurrencyValue(), items: [])).isEmpty)
    }

    @Test
    func emptyNestedObjectsAreRetainedAndEmptyStringsAreOmitted() throws {
        let data = mapper.mapOrder(
            Order(
                pickupInformation: PickupInformation(name: Name(), phone: "", address: Address(), email: ""),
                items: [Item(name: "", category: "", sku: "")]
            ))
        let expected: [String: Any] = ["items": [[:]], "pickupInformation": ["name": [:], "address": [:]]]
        #expect(try #require(unwrapForJSON(data) as? NSDictionary) == expected as NSDictionary)
        let pickupOnly = mapper.mapOrder(Order(pickupInformation: PickupInformation()))
        #expect((pickupOnly["pickupInformation"] as? [String: Any?])?.isEmpty == true)
    }

    @Test(arguments: [Int64(0), 1, -105, 12345])
    func convertsEveryMoneyFieldFromCentsAndPreservesZeroQuantity(cents: Int64) throws {
        let money = CurrencyValue(value: cents)
        let order = Order(
            subTotal: money, totalDiscounts: money, totalPrice: money, totalShipping: money, totalTax: money,
            items: [Item(quantity: 0, unitPrice: money, unitTax: money, shippingCost: money)]
        )
        let data = mapper.mapOrder(order)
        let expected = Double(cents) / 100
        for key in ["subTotalValue", "totalDiscountsValue", "totalPriceValue", "totalShippingValue", "totalTaxValue"] {
            #expect(data[key] as? Double == expected)
        }
        let item = try #require((data["items"] as? [[String: Any?]])?.first)
        for key in ["unitPriceValue", "unitTaxValue", "shippingCostValue"] {
            #expect(item[key] as? Double == expected)
        }
        #expect(item["quantity"] as? Int == 0)
        #expect(
            mapper.mapCommonData(placementData: PlacementData(order: order))["checkoutAmount"] as? Double == expected)
    }

    @Test(arguments: ["non-leasable", "nonleasable", "NON-LEASABLE", "NonLeasable"])
    func ineligibleCategoryDisablesBNPLRegardlessOfInitialValue(category: String) {
        let states: [Bool?] = [true, false, nil]
        for initialEligibility in states {
            var data = mapper.mapOrder(Order(items: [Item(category: category)], bnplEligible: initialEligibility))
            mapper.applyBNPLEligibility(&data)
            #expect(data["bnplEligible"] as? Bool == false)
        }
    }

    @Test(arguments: ["", "Furniture", " non-leasable", "non-leasable ", "non-leasable-tools"])
    func otherCategoriesPreserveEligibilityWithoutTrimmingOrPartialMatching(category: String) {
        let states: [Bool?] = [true, false, nil]
        for initialEligibility in states {
            var data = mapper.mapOrder(Order(items: [Item(category: category)], bnplEligible: initialEligibility))
            mapper.applyBNPLEligibility(&data)
            #expect(data["bnplEligible"] as? Bool == initialEligibility)
        }
    }

    @Test
    func eligibilityLeavesMissingEmptyAndInvalidItemDataUnchanged() {
        var empty: [String: Any?] = [:]
        mapper.applyBNPLEligibility(&empty)
        #expect(empty.isEmpty)

        let inputs: [[String: Any?]] = [
            ["bnplEligible": true],
            ["bnplEligible": true, "items": "not-an-array"],
            ["bnplEligible": true, "items": [] as [[String: Any?]]],
            ["bnplEligible": true, "items": [[:]] as [[String: Any?]]],
            ["bnplEligible": true, "items": [["category": 42]] as [[String: Any?]]],
        ]
        for input in inputs {
            var data = input
            mapper.applyBNPLEligibility(&data)
            #expect(data["bnplEligible"] as? Bool == true)
            #expect(data.keys.sorted() == input.keys.sorted())
        }
    }

    @Test
    func checkoutChecksEveryItemWithoutMutatingSourceOrder() throws {
        let order = Order(
            items: [Item(category: "Furniture"), Item(category: "NON-LEASABLE"), Item()], bnplEligible: true)
        let mapped = mapper.mapCheckoutData(placementData: PlacementData(order: order))
        let mappedOrder = try #require(mapped["order"] as? [String: Any?])
        #expect(mappedOrder["bnplEligible"] as? Bool == false)
        #expect((mappedOrder["items"] as? [[String: Any?]])?.count == 3)
        #expect(order.bnplEligible == true)
        #expect(order.items?[1].category == "NON-LEASABLE")
    }
}
