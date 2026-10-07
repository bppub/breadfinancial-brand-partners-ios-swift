//------------------------------------------------------------------------------
//  File:          AnalyticsPayloadBuilderTests.swift
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

@Suite struct AnalyticsPayloadBuilderTests {
    @Test(arguments: ["view-placement", "click-placement"])
    func absentResponseFieldsRetainEmptyObjectsNullLocationAndPlaceholders(name: String) throws {
        let payload = AnalyticsPayloadBuilder().build(
            name: name,
            placementResponse: PlacementsResponse(placements: nil, placementContent: nil),
            timestamp: "2026-10-06T12:34:56.789Z", apiKey: "", userAgent: "test-device"
        )
        let expected = """
            {
              "name": "\(name)",
              "props": {
                "eventProperties": {
                  "placement": {}, "placementContent": {}, "metadata": {"location": null}
                },
                "userProperties": {}
              },
              "context": {
                "timestamp": "2026-10-06T12:34:56.789Z", "apiKey": "",
                "browserCtx": {
                  "library": {"name": "bread-partners-sdk-ios", "version": "0.0.1"},
                  "userAgent": "test-device", "page": {"path": "ToDo"}
                },
                "trackingInfo": {"sessionTrackingId": "ToDO"}
              }
            }
            """
        #expect(
            try JSONSerialization.jsonObject(with: JSONEncoder().encode(payload)) as? NSDictionary
                == JSONSerialization.jsonObject(with: Data(expected.utf8)) as? NSDictionary
        )
    }

    @Test
    func selectsFirstPlacementAndFirstContentIndependentlyAndPreservesMetadata() throws {
        let responseJSON = """
            {
              "placements": [
              {"id": "first-placement", "content": {"contentId": "second-content"},
               "renderContext": {"LOCATION": "product", "SDK_TID": "tracking", "DATETIME": "ignored"}},
              {"id": "second-placement", "renderContext": {"LOCATION": "cart", "SDK_TID": "ignored"}}
              ],
              "placementContent": [
              {"id": "first-content", "contentType": "text", "contentData": {"htmlContent": "ignored"},
               "metadata": {"placementId": "metadata-placement", "productType": "card",
                      "messageId": "message", "templateId": "template"}},
              {"id": "second-content", "contentType": "overlay", "metadata": {"templateId": "ignored"}}
              ]
            }
            """
        let response = try JSONDecoder().decode(PlacementsResponse.self, from: Data(responseJSON.utf8))
        let payload = AnalyticsPayloadBuilder().build(
            name: "custom-event", placementResponse: response,
            timestamp: "supplied-timestamp", apiKey: "supplied-key", userAgent: "supplied-device"
        )
        let expected = """
            {
              "name": "custom-event",
              "props": {
              "eventProperties": {
                "placement": {"id": "first-placement", "placementContentId": "first-content",
                      "overlayContentId": "first-content"},
                "placementContent": {"id": "first-content", "contentType": "text",
                "metadata": {"placementId": "metadata-placement", "productType": "card",
                       "messageId": "message", "templateId": "template"}},
                "metadata": {"location": "product"}
              },
              "userProperties": {}
              },
              "context": {
              "timestamp": "supplied-timestamp", "apiKey": "supplied-key",
              "browserCtx": {
                "library": {"name": "bread-partners-sdk-ios", "version": "0.0.1"},
                "userAgent": "supplied-device", "page": {"path": "ToDo"}
              },
              "trackingInfo": {"userTrackingId": "tracking", "sessionTrackingId": "ToDO"}
              }
            }
            """
        #expect(
            try JSONSerialization.jsonObject(with: JSONEncoder().encode(payload)) as? NSDictionary
                == JSONSerialization.jsonObject(with: Data(expected.utf8)) as? NSDictionary
        )
        let decoded = try JSONDecoder().decode(Analytics.Payload.self, from: JSONEncoder().encode(payload))
        #expect(decoded.props?.eventProperties?.placementContent?.metadata?.templateId == "template")
        #expect(
            try JSONSerialization.jsonObject(with: JSONEncoder().encode(decoded)) as? NSDictionary
                == JSONSerialization.jsonObject(with: Data(expected.utf8)) as? NSDictionary
        )
    }

    @Test(arguments: [
        "{}", #"{"placements":[],"placementContent":[]}"#,
        #"{"placements":[{}, {"id":"ignored","renderContext":{"LOCATION":"ignored","SDK_TID":"ignored"}}],"placementContent":[{}, {"id":"ignored","contentType":"ignored","metadata":{"templateId":"ignored"}}]}"#,
    ])
    func missingOrEmptyFirstEntriesDoNotFallBackToLaterEntries(json: String) throws {
        let response = try JSONDecoder().decode(PlacementsResponse.self, from: Data(json.utf8))
        let payload = AnalyticsPayloadBuilder().build(
            name: "view-placement", placementResponse: response, timestamp: "", apiKey: "", userAgent: nil
        )
        let properties = try #require(payload.props?.eventProperties)
        #expect(try JSONEncoder().encode(properties.placement) == Data("{}".utf8))
        #expect(try JSONEncoder().encode(properties.placementContent) == Data("{}".utf8))
        #expect(properties.metadata?.keys.sorted() == ["location"])
        #expect(properties.metadata?["location"] as? String == nil)
        #expect(payload.context?.trackingInfo?.userTrackingId == nil)
        #expect(payload.context?.timestamp == "")
        #expect(payload.context?.apiKey == "")
        let browser =
            try JSONSerialization.jsonObject(
                with: JSONEncoder().encode(payload.context?.browserCtx)) as? [String: Any]
        #expect(browser?["userAgent"] == nil)
    }

    @Test
    func placementWithoutContentKeepsPlacementTrackingAndLocation() throws {
        let response = try JSONDecoder().decode(
            PlacementsResponse.self,
            from: Data(
                #"{"placements":[{"id":"placement","renderContext":{"SDK_TID":"tracking","LOCATION":""}}]}"#.utf8)
        )
        let payload = AnalyticsPayloadBuilder().build(
            name: "click-placement", placementResponse: response, timestamp: "timestamp", apiKey: "key", userAgent: ""
        )
        let properties = try #require(payload.props?.eventProperties)
        #expect(properties.placement?.id == "placement")
        #expect(properties.placement?.placementContentId == nil)
        #expect(properties.placement?.overlayContentId == nil)
        #expect(properties.metadata?["location"] as? String == "")
        #expect(payload.context?.trackingInfo?.userTrackingId == "tracking")
        #expect(payload.context?.browserCtx?.userAgent == "")
    }

    @Test
    func contentWithoutPlacementPreservesEmptyAndPartialMetadata() throws {
        let metadata = MetadataModel(placementId: "", productType: nil, messageId: " ", templateId: nil)
        let response = PlacementsResponse(
            placements: nil,
            placementContent: [PlacementContentModel(id: "", contentType: "", contentData: nil, metadata: metadata)]
        )
        let payload = AnalyticsPayloadBuilder().build(
            name: "", placementResponse: response, timestamp: "timestamp", apiKey: "key", userAgent: nil
        )
        let properties = try #require(payload.props?.eventProperties)
        #expect(properties.placement?.id == nil)
        #expect(properties.placement?.placementContentId == "")
        #expect(properties.placement?.overlayContentId == "")
        #expect(properties.placementContent?.contentType == "")
        #expect(
            try JSONSerialization.jsonObject(with: JSONEncoder().encode(properties.placementContent?.metadata))
                as? NSDictionary == ["placementId": "", "messageId": " "] as NSDictionary
        )
        #expect(payload.name == "")
        #expect(payload.context?.trackingInfo?.userTrackingId == nil)
    }

    @Test
    func repeatedBuildsUseOnlySuppliedContextValues() throws {
        let builder = AnalyticsPayloadBuilder()
        let response = PlacementsResponse(placements: nil, placementContent: nil)
        let first = builder.build(
            name: "view-placement", placementResponse: response, timestamp: "first", apiKey: "one",
            userAgent: "device-one")
        let second = builder.build(
            name: "view-placement", placementResponse: response, timestamp: "second", apiKey: "two",
            userAgent: "device-two")
        #expect(first.context?.timestamp == "first")
        #expect(first.context?.apiKey == "one")
        #expect(first.context?.browserCtx?.userAgent == "device-one")
        #expect(second.context?.timestamp == "second")
        #expect(second.context?.apiKey == "two")
        #expect(second.context?.browserCtx?.userAgent == "device-two")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        #expect(
            try encoder.encode(first)
                == encoder.encode(
                    builder.build(
                        name: "view-placement", placementResponse: response, timestamp: "first", apiKey: "one",
                        userAgent: "device-one"
                    )))
    }
}

@Suite struct AnalyticsModelsTests {
    @Test
    func constructsAndRoundTripsFieldsNotPopulatedByTheCurrentBuilder() throws {
        let payload = Analytics.Payload(
            name: "event",
            props: Analytics.Props(
                eventProperties: Analytics.EventProperties(
                    placement: nil, placementContent: nil,
                    metadata: ["absent": nil, "empty": ""], actionTarget: "target"
                ),
                userProperties: ["user": "value"]
            ),
            context: Analytics.Context(
                timestamp: nil, apiKey: nil,
                browserCtx: Analytics.BrowserCtx(
                    library: nil, userAgent: nil, page: Analytics.Page(path: nil, url: "https://example.com")
                ),
                trackingInfo: nil
            )
        )
        let expected = """
            {"name":"event","props":{"eventProperties":{"metadata":{"absent":null,"empty":""},
             "actionTarget":"target"},"userProperties":{"user":"value"}},
             "context":{"browserCtx":{"page":{"url":"https://example.com"}}}}
            """
        let data = try JSONEncoder().encode(payload)
        #expect(
            try JSONSerialization.jsonObject(with: data) as? NSDictionary
                == JSONSerialization.jsonObject(with: Data(expected.utf8)) as? NSDictionary
        )
        let decoded = try JSONDecoder().decode(Analytics.Payload.self, from: data)
        #expect(decoded.props?.eventProperties?.actionTarget == "target")
        #expect(decoded.context?.browserCtx?.page?.url == "https://example.com")
        #expect(decoded.props?.eventProperties?.metadata?.keys.contains("absent") == true)
        #expect(
            try JSONSerialization.jsonObject(with: JSONEncoder().encode(decoded)) as? NSDictionary
                == JSONSerialization.jsonObject(with: data) as? NSDictionary
        )
    }

    @Test(arguments: ["{}", #"{"name":null,"props":null,"context":null,"unknown":42}"#])
    func absentOrNullPayloadFieldsDecodeAndEncodeAsEmptyObject(json: String) throws {
        let payload = try JSONDecoder().decode(Analytics.Payload.self, from: Data(json.utf8))
        #expect(payload.name == nil)
        #expect(payload.props == nil)
        #expect(payload.context == nil)
        #expect(try JSONEncoder().encode(payload) == Data("{}".utf8))
        #expect(try JSONEncoder().encode(Analytics.Payload(name: nil, props: nil, context: nil)) == Data("{}".utf8))
    }

    @Test(arguments: [
        "[]", #"{"name":42}"#, #"{"props":{"userProperties":{"user":false}}}"#,
        #"{"props":{"eventProperties":{"metadata":{"location":42}}}}"#,
        #"{"props":{"eventProperties":{"placementContent":{"metadata":{"templateId":42}}}}}"#,
        #"{"context":{"browserCtx":{"userAgent":42}}}"#,
    ])
    func malformedFieldTypesRemainDecodingErrors(json: String) {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Analytics.Payload.self, from: Data(json.utf8))
        }
    }
}
