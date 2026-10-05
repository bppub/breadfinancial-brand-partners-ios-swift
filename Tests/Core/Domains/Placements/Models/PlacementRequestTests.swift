import BreadPartnersCore
import Foundation
import Testing

@Suite struct PlacementRequestTests {
    private let contextJSON = """
        {
          "SDK_TID":"tracking", "ENV":"STAGE", "RTPS_ID":"rtps", "BUYER_ID":"buyer",
          "PREQUAL_ID":"prequal", "PREQUAL_CREDIT_LIMIT":"1000", "LOCATION":"checkout",
          "PRICE":9223372036854775807, "EXISTING_CH":false, "CARDHOLDER_TIER":"gold",
          "STORE_NUMBER":"8883", "LOYALTY_ID":"loyalty", "OVERRIDE_KEY":"override",
          "CLIENT_VAR_1":"one", "CLIENT_VAR_2":"two", "CLIENT_VAR_3":"three", "CLIENT_VAR_4":"four",
          "DEPARTMENT_ID":"department", "channel":"O", "subchannel":"X", "CMP":"campaign",
          "ALLOW_CHECKOUT":true, "UPQ_PARAMS":"offer=params", "UPQ_CHECKOUT_PARAMS":"checkout=params",
          "embeddedUrl":"https://example.com/checkout"
        }
        """

    @Test
    func initializesAndEncodesEveryContextFieldWithOriginalJSONKeys() throws {
        let context = ContextRequestBody(
            SDK_TID: "tracking", ENV: "STAGE", RTPS_ID: "rtps", BUYER_ID: "buyer",
            PREQUAL_ID: "prequal", PREQUAL_CREDIT_LIMIT: "1000", LOCATION: "checkout",
            PRICE: Int64.max, EXISTING_CH: false, CARDHOLDER_TIER: "gold", STORE_NUMBER: "8883",
            LOYALTY_ID: "loyalty", OVERRIDE_KEY: "override", CLIENT_VAR_1: "one", CLIENT_VAR_2: "two",
            CLIENT_VAR_3: "three", CLIENT_VAR_4: "four", DEPARTMENT_ID: "department",
            channel: "O", subchannel: "X", CMP: "campaign", ALLOW_CHECKOUT: true,
            UPQ_PARAMS: "offer=params", UPQ_CHECKOUT_PARAMS: "checkout=params",
            embeddedUrl: "https://example.com/checkout"
        )
        let encoded = try JSONEncoder().encode(context)
        let expected = try JSONSerialization.jsonObject(with: Data(contextJSON.utf8)) as? NSDictionary
        #expect(try JSONSerialization.jsonObject(with: encoded) as? NSDictionary == expected)

        let decoded = try JSONDecoder().decode(ContextRequestBody.self, from: encoded)
        #expect(decoded.PRICE == Int64.max)
        #expect(decoded.EXISTING_CH == false)
        #expect(decoded.ALLOW_CHECKOUT == true)
        #expect(try JSONSerialization.jsonObject(with: JSONEncoder().encode(decoded)) as? NSDictionary == expected)
    }

    @Test
    func encodesAndDecodesNestedPlacementRequest() throws {
        let json = """
            {"brandId":"brand", "placements":[{"id":"placement", "context":\(contextJSON)}]}
            """
        let decoded = try JSONDecoder().decode(PlacementRequest.self, from: Data(json.utf8))
        #expect(decoded.brandId == "brand")
        #expect(decoded.placements?.count == 1)
        #expect(decoded.placements?.first?.id == "placement")
        #expect(decoded.placements?.first?.context?.PRICE == Int64.max)
        let constructed = PlacementRequest(
            placements: [PlacementRequestBody(id: "placement", context: decoded.placements?.first?.context)],
            brandId: "brand"
        )
        #expect(
            try JSONSerialization.jsonObject(with: JSONEncoder().encode(constructed)) as? NSDictionary
                == JSONSerialization.jsonObject(with: Data(json.utf8)) as? NSDictionary
        )
    }

    @Test
    func defaultInitializersOmitAllNilFields() throws {
        #expect(try JSONEncoder().encode(PlacementRequest()) == Data("{}".utf8))
        #expect(try JSONEncoder().encode(PlacementRequestBody()) == Data("{}".utf8))
        #expect(try JSONEncoder().encode(ContextRequestBody()) == Data("{}".utf8))
    }

    @Test(arguments: ["{}", #"{"placements":null,"brandId":null,"unknown":42}"#])
    func missingAndNullOptionalFieldsDecodeAsNil(json: String) throws {
        let request = try JSONDecoder().decode(PlacementRequest.self, from: Data(json.utf8))
        #expect(request.placements == nil)
        #expect(request.brandId == nil)
        #expect(try JSONEncoder().encode(request) == Data("{}".utf8))
    }

    @Test
    func emptyArrayAndEmptyNestedObjectsRemainDistinctFromNil() throws {
        let empty = try JSONDecoder().decode(PlacementRequest.self, from: Data(#"{"placements":[]}"#.utf8))
        #expect(empty.placements?.isEmpty == true)
        let nested = try JSONDecoder().decode(
            PlacementRequest.self, from: Data(#"{"placements":[{}, {"context":{"PRICE":null}}]}"#.utf8)
        )
        #expect(nested.placements?.count == 2)
        #expect(nested.placements?.first?.id == nil)
        #expect(nested.placements?.first?.context == nil)
        #expect(nested.placements?.last?.context?.PRICE == nil)
    }

    @Test
    func UPQFieldsRemainMutableAndCopyPreservesCurrentReplacementOnlyBehavior() throws {
        var context = try JSONDecoder().decode(ContextRequestBody.self, from: Data(contextJSON.utf8))
        context.UPQ_PARAMS = "updated-offer"
        context.UPQ_CHECKOUT_PARAMS = "updated-checkout"
        #expect(context.UPQ_PARAMS == "updated-offer")
        #expect(context.UPQ_CHECKOUT_PARAMS == "updated-checkout")

        let copied = context.copy(upqParams: "replacement-offer", upqCheckoutParams: "replacement-checkout")
        let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(copied)) as? NSDictionary
        #expect(
            object == ["UPQ_PARAMS": "replacement-offer", "UPQ_CHECKOUT_PARAMS": "replacement-checkout"] as NSDictionary
        )
        #expect(try JSONEncoder().encode(context.copy()) == Data("{}".utf8))
    }

    @Test(arguments: [
        "invalid JSON", "[]", "null", #"{"placements":{}}"#, #"{"brandId":42}"#,
        #"{"placements":[{"id":false}]}"#, #"{"placements":[{"context":[] }]}"#,
        #"{"placements":[{"context":{"PRICE":"100"}}]}"#,
        #"{"placements":[{"context":{"PRICE":1.25}}]}"#,
        #"{"placements":[{"context":{"PRICE":9223372036854775808}}]}"#,
        #"{"placements":[{"context":{"ALLOW_CHECKOUT":"true"}}]}"#,
    ])
    func malformedRequestsThrowDecodingErrors(json: String) {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(PlacementRequest.self, from: Data(json.utf8))
        }
    }
}
