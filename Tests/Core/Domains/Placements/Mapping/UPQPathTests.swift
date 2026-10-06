import BreadPartnersCore
import Foundation
import Testing

@Suite struct UPQPathTests {
    private let mapper = UPQMapper()

    @Test
    func offerPathIncludesBaseValuesAndEncodedCommonData() throws {
        let data = mapper.mapCommonData(
            placementData: PlacementData(order: Order(totalPrice: CurrencyValue(value: 12345))),
            merchantConfiguration: MerchantConfiguration(
                buyer: BreadPartnersBuyer(givenName: "Ada Lovelace"), paymentMode: .split)
        )
        let params = mapper.offerQueryParams(initialData: data, clientKey: "merchant key")
        let queryString = params.toQueryString()
        let query = try query(queryString)

        #expect(
            query == [
                "embedded": "true", "clientKey": "merchant key", "checkoutAmount": "123.45",
                "storeNumber": "8883", "firstName": "Ada Lovelace", "splitPayment": "true",
            ])
        #expect(queryString.contains("Ada%20Lovelace"))
        #expect(params["checkoutAmount"] as? Double == 123.45)
        #expect(params["embedded"] as? Bool == true)
    }

    @Test
    func checkoutMappingIncludesFinancingTrackingAndShippingWithoutOverwritingBilling() throws {
        let placement = PlacementData(
            order: Order(totalPrice: CurrencyValue(value: 101)), upqInSessionToken: "token",
            financingBuyerId: "buyer", prequalificationId: "prequal", prequalCreditLimit: "500"
        )
        let merchant = MerchantConfiguration(
            buyer: BreadPartnersBuyer(
                billingAddress: BreadPartnersAddress(address1: "Billing Street"),
                shippingAddress: BreadPartnersAddress(address1: "Shipping Street", address2: "", country: "ignored")
            ))
        let data = mapper.mapCheckoutData(
            placementData: placement, merchantConfiguration: merchant, sessionTrackingId: "session",
            userTrackingId: "tracking", financingLocationId: "location", callCenter: "call-center"
        )
        #expect(data["address1"] as? String == "Billing Street")
        #expect(data["checkoutAmount"] as? Double == 1.01)
        #expect(data["epSessionId"] as? String == "session")
        #expect(data["epId"] as? String == "tracking")
        #expect(data["financingBuyerId"] as? String == "buyer")
        #expect(data["prequalificationId"] as? String == "prequal")
        #expect(data["prequalCreditLimit"] as? String == "500")
        #expect(data["financingLocationId"] as? String == "location")
        #expect(data["callCenter"] as? String == "call-center")
        #expect(data["inSessionToken"] as? String == "token")

        let params = mapper.checkoutQueryParams(initialData: data, clientKey: "brand")
        let query = try query(params.toQueryString())
        let order = try jsonObject(try #require(query["order"]))
        let address = try jsonObject(try #require(query["shippingAddress"]))
        #expect(order["totalPriceValue"] as? Double == 1.01)
        #expect(address.keys.sorted() == ["address1"])
        #expect(address["address1"] as? String == "Shipping Street")
        #expect(params["order"] as? String == stringifyJSON(data["order"] as Any))
        #expect(params["shippingAddress"] as? String == stringifyJSON(data["shippingAddress"] as Any))
    }

    @Test
    func nestedJSONUsesExistingRoundingAndKeepsUnserializedQueryParams() throws {
        let order: [String: Any?] = [
            "totalPriceValue": 1.236,
            "items": [["quantity": 2, "unitPriceValue": 1.236, "name": "Chair"]] as [[String: Any?]],
            "missing": nil,
        ]
        let address: [String: Any?] = ["address1": "Shipping Street", "address2": nil]
        let params = mapper.checkoutQueryParams(
            initialData: ["order": order, "shippingAddress": address], clientKey: "brand")
        let queryString = params.toQueryString()
        let query = try query(queryString)
        let encodedOrder = try #require(query["order"])
        let decodedOrder = try jsonObject(encodedOrder)
        let items = try #require(decodedOrder["items"] as? [[String: Any]])

        #expect(decodedOrder["totalPriceValue"] as? Double == 1.24)
        #expect(decodedOrder["missing"] == nil)
        #expect(items.first?["quantity"] as? Int == 2)
        #expect(items.first?["unitPriceValue"] as? Double == 1.24)
        #expect(encodedOrder == stringifyJSON(order))
        #expect(query["shippingAddress"] == stringifyJSON(address))
        #expect(params["order"] as? String == stringifyJSON(order))
        #expect(queryString.contains("%0A"))
    }

    @Test
    func absentCheckoutInputsKeepEmptyOrderAndOmitFinancingAndShipping() throws {
        let data = mapper.mapCheckoutData(
            placementData: PlacementData(
                upqInSessionToken: "", financingBuyerId: "", prequalificationId: "", prequalCreditLimit: ""),
            sessionTrackingId: "", userTrackingId: "", financingLocationId: "", callCenter: ""
        )
        #expect(data.keys.sorted() == ["order"])
        #expect((data["order"] as? [String: Any?])?.isEmpty == true)
        #expect(mapper.mapCheckoutData().keys.sorted() == ["order"])
        let query = try query(mapper.checkoutQueryParams(initialData: data, clientKey: "brand").toQueryString())
        #expect(query["order"] == "{\n\n}")
        #expect(query["shippingAddress"] == nil)
    }

    @Test
    func initialDataOverridesBaseValuesAndOmitsNilValuesWhenSerialized() throws {
        let data: [String: Any?] = ["embedded": false, "clientKey": "override", "missing": nil]
        for params in [
            mapper.offerQueryParams(initialData: data, clientKey: "original"),
            mapper.checkoutQueryParams(initialData: data, clientKey: "original"),
        ] {
            #expect(try query(params.toQueryString()) == ["embedded": "false", "clientKey": "override"])
            #expect(params.keys.contains("missing"))
        }
        for params in [
            mapper.offerQueryParams(initialData: [:], clientKey: ""),
            mapper.checkoutQueryParams(initialData: [:], clientKey: ""),
        ] {
            #expect(try query(params.toQueryString()) == ["embedded": "true", "clientKey": ""])
        }
    }

    @Test
    func explicitNilAndInvalidNestedObjectsBecomeEmptyQueryValues() throws {
        let inputs: [[String: Any?]] = [
            ["order": nil, "shippingAddress": nil],
            ["order": 42, "shippingAddress": "not-an-object"],
        ]
        for input in inputs {
            let params = mapper.checkoutQueryParams(initialData: input, clientKey: "brand")
            let query = try query(params.toQueryString())
            #expect(query["order"] == "")
            #expect(query["shippingAddress"] == "")
            #expect(params["order"] as? String == "")
            #expect(params["shippingAddress"] as? String == "")
        }
    }

    @Test
    func queryEscapingRetainsExistingReservedCharacterBehavior() {
        let params = mapper.offerQueryParams(initialData: ["firstName": "Ada & Co"], clientKey: "brand")
        #expect(params.toQueryString().contains("firstName=Ada%20&%20Co"))
    }

    private func query(_ queryString: String) throws -> [String: String] {
        let components = try #require(URLComponents(string: "https://example.com?\(queryString)"))
        let items = try #require(components.queryItems)
        return Dictionary(
            uniqueKeysWithValues: items.compactMap { item in
                item.value.map { (item.name, $0) }
            })
    }

    private func jsonObject(_ value: String) throws -> [String: Any] {
        try #require(JSONSerialization.jsonObject(with: Data(value.utf8)) as? [String: Any])
    }
}
