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
                        "placementId" : "placementId",
                        "productType" : "productType",
                        "messageId" : "messageId",
                        "templateId" : "templateId",
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
                      "id" : "placementId",
                      "content" : {
                        "contentId" : "0"
                      },
                      "domId" : "",
                      "renderContext" : {
                        "channel" : "",
                        "PRICE" : 999999,
                        "ENV" : "STAGE",
                        "STORE_NUMBER" : "0000",
                        "UPQ_PARAMS" : "UPQ_PARAMS",
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
