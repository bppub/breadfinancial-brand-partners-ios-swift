import BreadPartnersCore
import Foundation
import Testing

@Suite struct PlacementResponseTests {
    private let responseJSON = """
        {
          "placements":[{
            "id":"placement", "content":{"contentId":"content"},
            "renderContext":{
              "LOCATION":"RTPS-Approval", "subchannel":"X", "RTPS_ID":"rtps", "PREQUAL_ID":"prequal",
              "PRICE":12345, "DATETIME":"2026-10-05", "SDK_TID":"tracking", "BUYER_ID":"buyer",
              "channel":"O", "PREQUAL_CREDIT_LIMIT":"1000", "ENV":"STAGE", "ALLOW_CHECKOUT":false,
              "embeddedUrl":"https://example.com/offer"
            }
          }],
          "placementContent":[{
            "id":"content", "contentType":"html", "contentData":{"htmlContent":"<p>Offer &amp; terms</p>"},
            "metadata":{"placementId":"placement", "productType":"card", "messageId":"message", "templateId":"overlay"}
          }]
        }
        """

    @Test
    func decodesNestedContentAndPreservesEveryJSONKeyOnRoundTrip() throws {
        let response = try JSONDecoder().decode(PlacementsResponse.self, from: Data(responseJSON.utf8))
        #expect(response.placements?.count == 1)
        #expect(response.placements?.first?.id == "placement")
        #expect(response.placements?.first?.content?.contentId == "content")
        #expect(response.placements?.first?.renderContext?.PRICE == 12345)
        #expect(response.placements?.first?.renderContext?.ALLOW_CHECKOUT == false)
        #expect(response.placementContent?.count == 1)
        #expect(response.placementContent?.first?.contentData?.htmlContent == "<p>Offer &amp; terms</p>")
        #expect(response.placementContent?.first?.metadata?.templateId == "overlay")
        #expect(
            try JSONSerialization.jsonObject(with: JSONEncoder().encode(response)) as? NSDictionary
                == JSONSerialization.jsonObject(with: Data(responseJSON.utf8)) as? NSDictionary
        )
    }

    @Test
    func memberwiseInitializersEncodeAllNestedFields() throws {
        let context = RenderContextModel(
            LOCATION: "RTPS-Approval", subchannel: "X", RTPS_ID: "rtps", PREQUAL_ID: "prequal",
            PRICE: 12345, DATETIME: "2026-10-05", SDK_TID: "tracking", BUYER_ID: "buyer",
            channel: "O", PREQUAL_CREDIT_LIMIT: "1000", ENV: "STAGE", ALLOW_CHECKOUT: false,
            embeddedUrl: "https://example.com/offer"
        )
        let response = PlacementsResponse(
            placements: [
                PlacementsModel(
                    id: "placement", content: PlacementContentReferenceModel(contentId: "content"),
                    renderContext: context
                )
            ],
            placementContent: [
                PlacementContentModel(
                    id: "content", contentType: "html",
                    contentData: ContentDataModel(htmlContent: "<p>Offer &amp; terms</p>"),
                    metadata: MetadataModel(
                        placementId: "placement", productType: "card", messageId: "message", templateId: "overlay")
                )
            ]
        )
        #expect(
            try JSONSerialization.jsonObject(with: JSONEncoder().encode(response)) as? NSDictionary
                == JSONSerialization.jsonObject(with: Data(responseJSON.utf8)) as? NSDictionary
        )
    }

    @Test(arguments: ["{}", #"{"placements":null,"placementContent":null,"unknown":42}"#])
    func absentAndNullArraysRemainNilAndEncodeWithoutKeys(json: String) throws {
        let response = try JSONDecoder().decode(PlacementsResponse.self, from: Data(json.utf8))
        #expect(response.placements == nil)
        #expect(response.placementContent == nil)
        #expect(try JSONEncoder().encode(response) == Data("{}".utf8))
        #expect(try JSONEncoder().encode(PlacementsResponse(placements: nil, placementContent: nil)) == Data("{}".utf8))
    }

    @Test
    func emptyArraysRemainEmptyInsteadOfNil() throws {
        let response = try JSONDecoder().decode(
            PlacementsResponse.self, from: Data(#"{"placements":[],"placementContent":[]}"#.utf8)
        )
        #expect(response.placements?.isEmpty == true)
        #expect(response.placementContent?.isEmpty == true)
    }

    @Test
    func emptyNestedObjectsAndUnknownFieldsAreAccepted() throws {
        let json =
            #"{"placements":[{"content":{},"renderContext":{"PRICE":null,"extra":"ignored"}}],"placementContent":[{"contentData":{},"metadata":{}}]}"#
        let response = try JSONDecoder().decode(PlacementsResponse.self, from: Data(json.utf8))
        #expect(response.placements?.first?.id == nil)
        #expect(response.placements?.first?.content?.contentId == nil)
        #expect(response.placements?.first?.renderContext?.PRICE == nil)
        #expect(response.placementContent?.first?.id == nil)
        #expect(response.placementContent?.first?.contentData?.htmlContent == nil)
        #expect(response.placementContent?.first?.metadata?.templateId == nil)
        let expected =
            #"{"placements":[{"content":{},"renderContext":{}}],"placementContent":[{"contentData":{},"metadata":{}}]}"#
        #expect(
            try JSONSerialization.jsonObject(with: JSONEncoder().encode(response)) as? NSDictionary
                == JSONSerialization.jsonObject(with: Data(expected.utf8)) as? NSDictionary
        )
    }

    @Test(arguments: [Int.min, Int.max])
    func renderContextPriceRetainsIntRange(price: Int) throws {
        let json = "{\"placements\":[{\"renderContext\":{\"PRICE\":\(price)}}]}"
        let response = try JSONDecoder().decode(PlacementsResponse.self, from: Data(json.utf8))
        #expect(response.placements?.first?.renderContext?.PRICE == price)
    }

    @Test(arguments: [
        "invalid JSON", "[]", "null", #"{"placements":{}}"#, #"{"placementContent":{}}"#,
        #"{"placements":[null]}"#, #"{"placements":[{"id":42}]}"#,
        #"{"placements":[{"content":{"contentId":42}}]}"#,
        #"{"placements":[{"renderContext":{"PRICE":"100"}}]}"#,
        #"{"placements":[{"renderContext":{"PRICE":1.25}}]}"#,
        #"{"placements":[{"renderContext":{"ALLOW_CHECKOUT":1}}]}"#,
        #"{"placementContent":[{"contentData":{"htmlContent":false}}]}"#,
        #"{"placementContent":[{"metadata":{"templateId":[]}}]}"#,
    ])
    func malformedResponsesThrowDecodingErrors(json: String) {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(PlacementsResponse.self, from: Data(json.utf8))
        }
    }
}
