//------------------------------------------------------------------------------
//  File:          PlacementContentResolverTests.swift
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
import Testing

@testable import BreadPartners

@Suite
struct PlacementContentResolverTests {
    private let resolver = BreadPartners.PlacementContentResolver()

    @Test(arguments: [nil, []] as [[PlacementContentModel]?])
    func missingContentReturnsNil(content: [PlacementContentModel]?) {
        #expect(resolver.overlayHTMLContent(in: response(content)) == nil)
    }

    @Test
    func missingMetadataReturnsNilEvenForOverlayContentType() {
        let content = PlacementContentModel(
            id: "popup", contentType: "overlay",
            contentData: ContentDataModel(htmlContent: "<p>popup</p>"), metadata: nil
        )

        #expect(resolver.overlayHTMLContent(in: response([content])) == nil)
    }

    @Test(arguments: [nil, "", "text", "PROMO-OVERLAY"] as [String?])
    func nonmatchingTemplateReturnsNil(templateId: String?) {
        #expect(resolver.overlayHTMLContent(in: response([content(templateId: templateId)])) == nil)
    }

    @Test(arguments: ["overlay", "promo-overlay-v2"])
    func selectsFirstCaseSensitiveSubstringMatch(templateId: String) {
        let firstHTML = "  <p>first popup</p>  "
        let contents = [
            content(templateId: nil),
            content(templateId: "text"),
            content(templateId: "PROMO-OVERLAY"),
            content(templateId: templateId, contentData: ContentDataModel(htmlContent: firstHTML)),
            content(contentData: ContentDataModel(htmlContent: "<p>second popup</p>")),
        ]

        #expect(resolver.overlayHTMLContent(in: response(contents)) == firstHTML)
    }

    @Test(
        arguments: [nil, ContentDataModel(htmlContent: nil), ContentDataModel(htmlContent: "")] as [ContentDataModel?])
    func matchingContentWithoutHTMLReturnsEmptyString(contentData: ContentDataModel?) {
        #expect(resolver.overlayHTMLContent(in: response([content(contentData: contentData)])) == "")
    }

    @Test
    func firstMatchWithoutHTMLDoesNotFallThroughToLaterMatch() {
        let contents = [
            content(contentData: nil),
            content(contentData: ContentDataModel(htmlContent: "<p>later popup</p>")),
        ]

        #expect(resolver.overlayHTMLContent(in: response(contents)) == "")
    }

    private func content(
        templateId: String? = "overlay",
        contentData: ContentDataModel? = ContentDataModel(htmlContent: "<p>popup</p>")
    ) -> PlacementContentModel {
        PlacementContentModel(
            id: "popup", contentType: "HTML", contentData: contentData,
            metadata: MetadataModel(placementId: nil, productType: nil, messageId: nil, templateId: templateId)
        )
    }

    private func response(_ content: [PlacementContentModel]?) -> PlacementsResponse {
        PlacementsResponse(placements: nil, placementContent: content)
    }
}
