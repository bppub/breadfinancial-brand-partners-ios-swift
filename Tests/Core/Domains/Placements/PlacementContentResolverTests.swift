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

import Testing

@testable import BreadPartnersCore

@Suite
struct PlacementContentResolverTests {
    private let resolver = PlacementContentResolver()

    @Test
    func firstTextContentSelectsTheFirstItemWithoutFiltering() throws {
        let text = content(id: "text", templateId: nil)
        let overlay = content(id: "overlay", templateId: "overlay")

        let selected = try resolver.firstTextContent(in: response([text, overlay]))

        #expect(selected.id == "text")
    }

    @Test
    func firstOverlayTemplateSelectsFirstCaseSensitiveSubstringMatch() throws {
        let nonOverlay = content(id: "text", templateId: "textual")
        let uppercaseOverlay = content(id: "uppercase", templateId: "PROMO-OVERLAY")
        let firstOverlay = content(id: "first", templateId: "promo-overlay-v2")
        let secondOverlay = content(id: "second", templateId: "overlay")

        let selected = try resolver.firstOverlayTemplate(
            in: response([nonOverlay, uppercaseOverlay, firstOverlay, secondOverlay])
        )

        #expect(selected.id == "first")
    }

    @Test
    func actionContentSelectsTheFirstExactIDMatch() throws {
        let firstMatch = content(id: "popup", templateId: "first")
        let secondMatch = content(id: "popup", templateId: "second")

        let selected = try resolver.actionContent(
            in: response([content(id: "text", templateId: nil), firstMatch, secondMatch]),
            actionContentId: "popup"
        )

        #expect(selected.metadata?.templateId == "first")
    }

    @Test
    func actionContentPreservesOptionalIDEquality() throws {
        let missingID = content(id: nil, templateId: "missing-id")

        let selected = try resolver.actionContent(in: response([missingID]), actionContentId: nil)

        #expect(selected.metadata?.templateId == "missing-id")
    }

    @Test
    func popupFollowUpSelectsTheFirstReturnedItem() throws {
        let first = content(id: "unrelated", templateId: "first")
        let requested = content(id: "requested", templateId: "requested")

        let selected = try resolver.firstPopupFollowUpContent(in: response([first, requested]))

        #expect(selected.id == "unrelated")
    }

    @Test(arguments: [0, 1, 2, 3])
    func missingContentPreservesOperationSpecificError(operation: Int) {
        let emptyResponse = response([])

        switch operation {
        case 0:
            #expect(throws: PlacementContentResolutionError.missingTextContent) {
                try resolver.firstTextContent(in: emptyResponse)
            }
        case 1:
            #expect(throws: PlacementContentResolutionError.missingOverlayTemplate) {
                try resolver.firstOverlayTemplate(in: emptyResponse)
            }
        case 2:
            #expect(throws: PlacementContentResolutionError.missingActionContent(actionContentId: "missing")) {
                try resolver.actionContent(in: emptyResponse, actionContentId: "missing")
            }
        default:
            #expect(throws: PlacementContentResolutionError.missingPopupFollowUpContent) {
                try resolver.firstPopupFollowUpContent(in: emptyResponse)
            }
        }
    }

    private func content(id: String?, templateId: String?) -> PlacementContentModel {
        PlacementContentModel(
            id: id,
            contentType: "HTML",
            contentData: ContentDataModel(htmlContent: "<p>content</p>"),
            metadata: MetadataModel(placementId: nil, productType: nil, messageId: nil, templateId: templateId)
        )
    }

    private func response(_ content: [PlacementContentModel]) -> PlacementsResponse {
        PlacementsResponse(placements: nil, placementContent: content)
    }
}
