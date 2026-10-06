import BreadPartnersCore
import Foundation
import Testing

@Suite struct PlacementRequestBuilderTests {
    @Test(arguments: BreadPartnersEnvironment.allCases)
    func nilConfigurationsEncodeDefaultsAndExplicitEnvironment(environment: BreadPartnersEnvironment) throws {
        let builder = PlacementRequestBuilder(
            integrationKey: "brand", merchantConfiguration: nil, placementConfig: nil, environment: environment
        )
        let request = builder.build()
        let context = try #require(request.placements?.first?.context)
        let query = try #require(context.UPQ_PARAMS)
        #expect(Set(query.components(separatedBy: "&")) == ["embedded=true", "clientKey=brand"])
        let expected: NSDictionary = [
            "brandId": "brand",
            "placements": [
                [
                    "context": [
                        "ENV": environment.rawValue, "channel": "X", "subchannel": "X",
                        "ALLOW_CHECKOUT": false, "UPQ_PARAMS": query,
                    ]
                ]
            ],
        ]
        #expect(try JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? NSDictionary == expected)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        #expect(try encoder.encode(builder.build()) == encoder.encode(request))
    }

    @Test(arguments: BreadPartnersLocationType.allCases)
    func channelUsesMerchantThenLocationIncludingEmptyOverrides(location: BreadPartnersLocationType) throws {
        let placement = PlacementData(locationType: location)
        for channel in [nil, "merchant", "", " "] as [String?] {
            let request = PlacementRequestBuilder(
                integrationKey: "brand",
                merchantConfiguration: MerchantConfiguration(channel: channel, subchannel: channel),
                placementConfig: placement, environment: .stage
            ).build()
            let context = try #require(request.placements?.first?.context)
            #expect(context.channel == (channel ?? location.channelCode))
            #expect(context.subchannel == (channel ?? "X"))
            #expect(context.LOCATION == location.rawValue)
            #expect(context.STORE_NUMBER == "8883")
            let params = try query(try #require(context.UPQ_PARAMS))
            #expect(params["channel"] == (channel == "" ? nil : channel))
            #expect(params["subchannel"] == (channel == "" ? nil : channel))
        }
    }

    @Test(arguments: [nil, false, true] as [Bool?])
    func checkoutIsSelectedOnlyByExplicitTrue(allowCheckout: Bool?) throws {
        let request = PlacementRequestBuilder(
            integrationKey: "brand",
            merchantConfiguration: nil,
            placementConfig: PlacementData(locationType: .checkout, allowCheckout: allowCheckout),
            environment: .uat
        ).build()
        let context = try #require(request.placements?.first?.context)
        #expect(context.ALLOW_CHECKOUT == (allowCheckout ?? false))
        if allowCheckout == true {
            #expect(context.UPQ_PARAMS == nil)
            let params = try query(try #require(context.UPQ_CHECKOUT_PARAMS))
            #expect(params == ["embedded": "true", "clientKey": "brand", "location": "checkout", "order": "{\n\n}"])
        } else {
            #expect(context.UPQ_CHECKOUT_PARAMS == nil)
            #expect(
                try query(try #require(context.UPQ_PARAMS)) == [
                    "embedded": "true", "clientKey": "brand", "location": "checkout",
                ])
        }
    }

    @Test
    func blankContextStringsAreOmittedButQueryWhitespaceAndEmptyIdentifiersRemain() throws {
        let request = PlacementRequestBuilder(
            integrationKey: "",
            merchantConfiguration: MerchantConfiguration(
                loyaltyID: "", campaignID: "", departmentId: "", cardholderTier: "", env: .prod,
                overrideKey: "", clientVariable1: "", clientVariable2: " ", clientVariable3: "", clientVariable4: ""
            ),
            placementConfig: PlacementData(placementId: ""), environment: .stage
        ).build()
        let context = try #require(request.placements?.first?.context)
        let params = try #require(context.UPQ_PARAMS)
        #expect(
            try query(params) == [
                "embedded": "true", "clientKey": "", "storeNumber": "8883", "clientVariable2": " ",
            ])
        let expected: NSDictionary = [
            "brandId": "",
            "placements": [
                [
                    "id": "",
                    "context": [
                        "ENV": "STAGE", "STORE_NUMBER": "8883",
                        "channel": "X", "subchannel": "X", "ALLOW_CHECKOUT": false, "UPQ_PARAMS": params,
                    ],
                ]
            ],
        ]
        #expect(try JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? NSDictionary == expected)
    }

    @Test
    func encodedCheckoutRetainsContextAndNestedMapperData() throws {
        let request = PlacementRequestBuilder(
            integrationKey: "brand key",
            merchantConfiguration: MerchantConfiguration(
                buyer: BreadPartnersBuyer(
                    givenName: "Ada Lovelace",
                    billingAddress: BreadPartnersAddress(address1: "Billing Street"),
                    shippingAddress: BreadPartnersAddress(
                        address1: "Shipping Street", locality: "Columbus", region: "OH")
                ),
                loyaltyID: "loyalty", campaignID: "campaign", storeNumber: "1234", departmentId: "department",
                cardholderTier: "gold", env: .prod, channel: "merchant", subchannel: "web",
                overrideKey: "override", clientVariable1: "one", clientVariable2: "two",
                clientVariable3: "three", clientVariable4: "four", paymentMode: .split
            ),
            placementConfig: PlacementData(
                locationType: .product, placementId: "placement", allowCheckout: true,
                order: Order(totalPrice: CurrencyValue(value: 12345)), upqInSessionToken: "token",
                financingBuyerId: "buyer", prequalificationId: "prequal", prequalCreditLimit: "500"
            ), environment: .uat
        ).build()
        let context = try #require(request.placements?.first?.context)
        let encodedQuery = try #require(context.UPQ_CHECKOUT_PARAMS)
        let params = try query(encodedQuery)
        #expect(encodedQuery.contains("Ada%20Lovelace"))
        #expect(
            params == [
                "embedded": "true", "clientKey": "brand key", "firstName": "Ada Lovelace",
                "address1": "Billing Street", "storeNumber": "1234", "loyaltyNumber": "loyalty",
                "departmentId": "department", "checkoutAmount": "123.45", "location": "product",
                "epPlacementId": "placement", "channel": "merchant", "subchannel": "web",
                "clientVariable1": "one", "clientVariable2": "two", "clientVariable3": "three",
                "clientVariable4": "four",
                "overrideKey": "override", "splitPayment": "true", "inSessionToken": "token",
                "financingBuyerId": "buyer", "prequalificationId": "prequal", "prequalCreditLimit": "500",
                "order": try #require(params["order"]), "shippingAddress": try #require(params["shippingAddress"]),
            ])
        let order = try JSONSerialization.jsonObject(with: Data(try #require(params["order"]).utf8)) as? NSDictionary
        let shipping =
            try JSONSerialization.jsonObject(with: Data(try #require(params["shippingAddress"]).utf8)) as? NSDictionary
        #expect(order == ["totalPriceValue": 123.45] as NSDictionary)
        #expect(shipping == ["address1": "Shipping Street", "city": "Columbus", "state": "OH"] as NSDictionary)
        let expected: NSDictionary = [
            "brandId": "brand key",
            "placements": [
                [
                    "id": "placement",
                    "context": [
                        "ENV": "UAT", "LOCATION": "product", "PRICE": 12345, "CARDHOLDER_TIER": "gold",
                        "STORE_NUMBER": "1234", "LOYALTY_ID": "loyalty", "OVERRIDE_KEY": "override",
                        "CLIENT_VAR_1": "one", "CLIENT_VAR_2": "two", "CLIENT_VAR_3": "three", "CLIENT_VAR_4": "four",
                        "DEPARTMENT_ID": "department", "channel": "merchant", "subchannel": "web", "CMP": "campaign",
                        "ALLOW_CHECKOUT": true, "UPQ_CHECKOUT_PARAMS": encodedQuery,
                    ],
                ]
            ],
        ]
        #expect(try JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? NSDictionary == expected)
    }

    private func query(_ value: String) throws -> [String: String] {
        let components = try #require(URLComponents(string: "https://example.com?\(value)"))
        return Dictionary(
            uniqueKeysWithValues: try #require(components.queryItems).compactMap { item in
                item.value.map { (item.name, $0) }
            })
    }
}
