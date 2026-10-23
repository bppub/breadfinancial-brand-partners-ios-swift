//------------------------------------------------------------------------------
//  File:          Fixtures.swift
//  Author(s):     Bread Financial
//
//  Description:   Canned responses served by MockHTTPServer during UI tests.
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
    
    static let RTPSConfig =  MockHttpResponse(match: "/config",
      jsonString: #"""
             {
               "config" : {
                 "rsk_STAGE_NATIVE_IOS" : "6LdnzgEsAAAAAKYpbXTEteGTij6Kl24JQFVt0yMR",
                 "styleFilename" : "academy",
                 "rsk_PROD_NATIVE_IOS" : "6Ld1Aa0qAAAAALp2csZ6qg83ImmBTwqNaNxaHx1Z",
                 "recaptchaSiteKeyPROD" : "6LcKBs4kAAAAAIH0EYXNtFVB-GpJsRSTtC0r-0sk",
                 "clientName" : "myacademy",
                 "rsk_UAT_NATIVE_IOS" : "6Lc-xwEsAAAAAG-vw4WV4vCfqBezJYYlzuVhhgxN",
                 "rsk_UAT_NATIVE_ANDROID" : "6LdNKwEsAAAAAAnAkQF_UT7FjLLykXj3yF9VdS9D",
                 "recaptchaEnabledPROD" : "manual",
                 "rsk_PROD_NATIVE_ANDROID" : "6Ldai6wqAAAAAAaYMIgzUKlNAO3zTLHnOL7Fce0w",
                 "rsk_STAGE_NATIVE_ANDROID" : "6LeOewEsAAAAAJZ-4RqAvVBA3gn6Sj6ybo2LXcYK",
                 "recaptchaEnabledQA" : "manual",
                 "recaptchaSiteKeyQA" : "6LcKBs4kAAAAAIH0EYXNtFVB-GpJsRSTtC0r-0sk",
                 "AEMContent" : "true"
               }
             }
             """#
     )
    
    static let RTPSPrescreen = MockHttpResponse(
        match: "/prescreen",
        jsonString: #"""
                    {
                      "correlationData" : null,
                      "creditTermNumber" : 57,
                      "purgeDate" : "20261122",
                      "newOffer" : true,
                      "creditLimt" : "2500",
                      "existingAccount" : false,
                      "expirationDate" : "20261218",
                      "returnCode" : "01",
                      "cardType" : null,
                      "customerNumber" : null,
                      "prescreenId" : 75981210,
                      "_debug" : {
                        "requests" : null
                      },
                      "startDate" : "20260908",
                      "prescreenInd" : "O"
                    }
                    """#
        )
    
    static let RTPSGeneratePlacemnt = MockHttpResponse(
        match: "/generatePlacements",
        jsonString: #"""
                    {
                      "placementContent" : [
                        {
                          "metadata" : {
                            "placementId" : "rtps-approval-overlay-academy",
                            "productType" : "CARD",
                            "messageId" : "0bf686a7-1454-4241-bca7-8f8f5b832dd9",
                            "templateId" : "rtps-banner-overlay-template",
                            "adobe" : null
                          },
                          "id" : "0",
                          "contentType" : "SSRTextPlacementContent",
                          "contentData" : {
                            "htmlContent" : "<div class=\"modal-header \"> <div class=\"left\"> <div class=\"brand logo\"><img tabindex=\"-1\" src=\"https:\/\/eds-content.comenity.net\/content\/dam\/aemacquisition\/ep\/en_us\/academy\/assets\/images\/logos\/ASO-MyAcademy-Logo.png\" alt=\"Brand Logo\"><\/div> <\/div> <div class=\"right\"> <\/div> <\/div> <div class=\"modal-body \" data-overlay-metadata data-overlay-type=\"EMBEDDED_OVERLAY\"> <iframe src=\"https:\/\/acquire1stage.comenity.net\/prescreen\/offer?prescreenId&#x3D;48346512&amp;embedded&#x3D;true&amp;urlPath&#x3D;screen%20name&amp;firstName&#x3D;John&amp;city&#x3D;City&amp;address1&#x3D;Address1&amp;mockPA&#x3D;success&amp;lastName&#x3D;Doe&amp;storeNumber&#x3D;8883&amp;clientKey&#x3D;15a64a51-104d-4ad3-915f-911b6ef63cfd&amp;mockMO&#x3D;success&amp;mockVL&#x3D;success&amp;state&#x3D;Ny&amp;zip&#x3D;12345&amp;location&#x3D;checkout\" style=\"width: 100%; height: 98%; display: block;\" frameborder=\"0\"><\/iframe> <\/div>"
                          }
                        }
                      ],
                      "placements" : [
                        {
                          "id" : "rtps-approval-overlay-academy",
                          "content" : {
                            "contentId" : "0"
                          },
                          "domId" : "",
                          "renderContext" : {
                            "ENV" : "STAGE",
                            "DATETIME" : "2026-10-21T10:36:34.473781633-04:00",
                            "LOCATION" : "RTPS-Approval",
                            "embeddedUrl" : "https:\/\/acquire1stage.comenity.net\/prescreen\/offer?prescreenId=48346512&embedded=true&urlPath=screen%20name&firstName=John&city=City&address1=Address1&mockPA=success&lastName=Doe&storeNumber=8883&clientKey=15a64a51-104d-4ad3-915f-911b6ef63cfd&mockMO=success&mockVL=success&state=Ny&zip=12345&location=checkout"
                          }
                        }
                      ]
                    }
                    """#
        )
}
