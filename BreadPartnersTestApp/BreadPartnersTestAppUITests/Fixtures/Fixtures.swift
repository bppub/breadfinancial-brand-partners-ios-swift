//------------------------------------------------------------------------------
//  File:          Fixtures.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing canned JSON payloads for the endpoints exercised by UI tests.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

/// Canned JSON payloads for the endpoints exercised by UI tests.
///
/// Replace the placeholder bodies with captured real responses to render actual
/// placement content. The brand-config stub is required for *every* test because
/// `BreadPartnersSDK.setup` fetches it before any other call.
enum Fixtures {

    /// Minimal brand config returned from `/brands/{id}/config`.
    static let brandConfig = MockHttpResponse(
        match: "/config",
        jsonString: #"{ "brandId": "test-brand", "config": {} }"#
    )

    /// Minimal brand style returned from `/brands/{id}/style`.
    static let brandStyle = MockHttpResponse(
        match: "/style",
        jsonString: #"{ "style": {} }"#
    )

    /// Placeholder placements response returned from `/generatePlacements`.
    /// Replace with a captured response to assert on rendered content.
    static let PALAPlacement = MockHttpResponse(
        match: "/generatePlacements",
        jsonString: #"""
                {
                  "placementContent" : [
                    {
                      "metadata" : {
                        "placementId" : "e6595a74-659d-431b-88d4-0146a5b4578c",
                        "productType" : "CARD",
                        "messageId" : "928d351d-06f5-4251-afd1-ed0bd2de4775",
                        "templateId" : "pala-template-bold",
                        "adobe" : null
                      },
                      "id" : "0",
                      "contentType" : "SSRTextPlacementContent",
                      "contentData" : {
                        "htmlContent" : "<div class=\"ep-text-placement\"data-action-type=\"NO_ACTION\" data-action-target=\"placement-primary-cta\"> Pay as low as <strong><span class=\"alliance-as-low-as-amount\">$255\/mo<\/span> for 12 months<\/strong> with the Zales Credit Card for a total payment of $3059.<sup>♢<\/sup> <\/div>"
                      }
                    }
                  ],
                  "placements" : [
                    {
                      "id" : "e6595a74-659d-431b-88d4-0146a5b4578c",
                      "content" : {
                        "contentId" : "0"
                      },
                      "domId" : "",
                      "renderContext" : {
                        "channel" : "",
                        "PRICE" : 299900,
                        "ENV" : "STAGE",
                        "STORE_NUMBER" : "8883",
                        "UPQ_PARAMS" : "storeNumber=8883&location=checkout&checkoutAmount=2999.00&clientKey=653b0802-06a5-468a-aa94-d782a27f3c7b&epPlacementId=e6595a74-659d-431b-88d4-0146a5b4578c&embedded=true",
                        "LOCATION" : "checkout",
                        "subchannel" : "",
                        "ALLOW_CHECKOUT" : false,
                        "DATETIME" : "2026-10-20T15:37:51.861263920-04:00"
                      }
                    }
                  ]
                }
                """#
    )
}
