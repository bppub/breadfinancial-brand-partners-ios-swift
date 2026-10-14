//------------------------------------------------------------------------------
//  File:          RTPSPopupModelMapperTests.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Foundation
import Testing

@testable import BreadPartners

@Suite
struct RTPSPopupModelMapperTests {
    @Test
    func mapsOverlayContentAndRenderContext() async throws {
        let model = try await RTPSPopupModelMapper().map(response())

        #expect(model.overlayType == "EMBEDDED_OVERLAY")
        #expect(model.location == "checkout")
        #expect(model.webViewUrl == "https://embedded.test")
        #expect(model.overlayTitle.string == "Title")
    }

    @Test
    func overridesParsedPopupValuesWithRTPSPlacementValues() async throws {
        let model = try await RTPSPopupModelMapper().map(
            response(
                contentData: ContentDataModel(
                    htmlContent: """
                        <div data-overlay-metadata data-overlay-type="SINGLE_PRODUCT_OVERLAY"></div>
                        <iframe src="https://html.test"></iframe>
                        <div class="epjs-css-overlay-title">Title</div>
                        """
                ),
                renderContext: RenderContextModel(
                    LOCATION: "rtps-checkout",
                    subchannel: nil,
                    RTPS_ID: nil,
                    PREQUAL_ID: nil,
                    PRICE: nil,
                    DATETIME: nil,
                    SDK_TID: nil,
                    BUYER_ID: nil,
                    channel: nil,
                    PREQUAL_CREDIT_LIMIT: nil,
                    ENV: nil,
                    ALLOW_CHECKOUT: nil,
                    embeddedUrl: "https://rtps.test"
                )
            )
        )

        #expect(model.overlayType == "EMBEDDED_OVERLAY")
        #expect(model.location == "rtps-checkout")
        #expect(model.webViewUrl == "https://rtps.test")
    }

    @Test
    func rejectsMissingPlacement() async {
        do {
            _ = try await RTPSPopupModelMapper().map(
                PlacementsResponse(placements: nil, placementContent: nil)
            )
            Issue.record("Expected missingPlacement")
        } catch RTPSPopupModelMapperError.missingPlacement {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func rejectsMissingOverlayContent() async {
        do {
            _ = try await RTPSPopupModelMapper().map(
                response(templateId: "text")
            )
            Issue.record("Expected missingOverlayContent")
        } catch RTPSPopupModelMapperError.missingOverlayContent {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func defaultsMissingHTMLAndRenderContext() async throws {
        let model = try await RTPSPopupModelMapper().map(
            response(contentData: nil, renderContext: nil)
        )

        #expect(model.overlayTitle.string == "")
        #expect(model.location == nil)
        #expect(model.webViewUrl == "")
    }

    private func response(
        templateId: String = "overlay",
        contentData: ContentDataModel? = ContentDataModel(
            htmlContent: "<div class=\"epjs-css-overlay-title\">Title</div>"
        ),
        renderContext: RenderContextModel? = RenderContextModel(
            LOCATION: "checkout",
            subchannel: nil,
            RTPS_ID: nil,
            PREQUAL_ID: nil,
            PRICE: nil,
            DATETIME: nil,
            SDK_TID: nil,
            BUYER_ID: nil,
            channel: nil,
            PREQUAL_CREDIT_LIMIT: nil,
            ENV: nil,
            ALLOW_CHECKOUT: nil,
            embeddedUrl: "https://embedded.test"
        )
    ) -> PlacementsResponse {
        PlacementsResponse(
            placements: [
                PlacementsModel(
                    id: "placement-id",
                    content: nil,
                    renderContext: renderContext
                )
            ],
            placementContent: [
                PlacementContentModel(
                    id: "content-id",
                    contentType: "text/html",
                    contentData: contentData,
                    metadata: MetadataModel(
                        placementId: "placement-id",
                        productType: nil,
                        messageId: nil,
                        templateId: templateId
                    )
                )
            ]
        )
    }
}
