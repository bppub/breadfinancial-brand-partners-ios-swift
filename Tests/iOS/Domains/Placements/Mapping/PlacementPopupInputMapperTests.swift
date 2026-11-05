//------------------------------------------------------------------------------
//  File:          PlacementPopupInputMapperTests.swift
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
import UIKit

@testable import BreadPartners

@Suite
@MainActor
struct PlacementPopupInputMapperTests {
    @Test
    func mapsEmbeddedOverlayAndAppliesRTPSCloseButtonRule() {
        let model = makeModel(location: "RTPS-Approval")
        let input = PlacementPopupInputMapper().map(
            model,
            overlayType: .embeddedOverlay,
            loadFollowUp: nil
        )

        #expect(input.style.loaderColor == PopUpStyling().loaderColor)
        #expect(input.chromeConfiguration.logoURL == "https://brand.test/logo.png")
        #expect(!input.chromeConfiguration.showsCloseButton)
        guard case let .embedded(content) = input.content else {
            Issue.record("Expected embedded popup content")
            return
        }
        #expect(content.logoURL == "https://brand.test/logo.png")
        #expect(content.webViewURL == "https://content.test")
        #expect(!content.showsCloseButton)
    }

    @Test
    func mapsProductFieldsSectionsAndFollowUpContent() async throws {
        let action = PrimaryActionButtonModel(
            dataContentFetch: "cta-fetch-id",
            buttonText: nil
        )
        let model = makeModel(
            primaryActionButtonAttributes: action,
            bodyDiv: [
                "div2": .init(tagValuePairs: ["p": "Second"]),
                "div1": .init(tagValuePairs: ["connector": "plus", "h3": "First"]),
            ]
        )
        let style = PopUpStyling(loaderColor: .systemRed)
        let followUpModel = makeModel(location: "RTPS-Approval")
        let input = PlacementPopupInputMapper().map(
            model,
            overlayType: .singleProductOverlay,
            style: style,
            loadFollowUp: { placementID in
                guard placementID == "cta-fetch-id" else { return nil }
                return followUpModel
            }
        )

        #expect(input.style.loaderColor == style.loaderColor)
        guard case let .product(product) = input.content else {
            Issue.record("Expected product popup content")
            return
        }
        #expect(product.logoURL == "https://brand.test/logo.png")
        #expect(product.title.string == "Offer title")
        #expect(product.subtitle.string == "Offer subtitle")
        #expect(product.header.string == "Offer heading")
        #expect(product.sections.map(\.tag) == ["h3", "connector", "p"])
        #expect(product.sections.map(\.text) == ["First", "plus", "Second"])
        #expect(product.disclosure.string == "Disclosure")
        #expect(product.disclosureHTML == "<p>Disclosure</p>")
        #expect(product.actionTitle == "Action")
        #expect(product.actionPlacementID == "cta-fetch-id")
        #expect(product.showsCloseButton)

        let loadActionContent = try #require(product.loadActionContent)
        let followUpContent = try await loadActionContent(product.actionPlacementID)
        #expect(followUpContent?.logoURL == "https://brand.test/logo.png")
        #expect(followUpContent?.webViewURL == "https://content.test")
        #expect(followUpContent?.showsCloseButton == false)
    }

    @Test
    func productWithoutFollowUpLoaderHasNoActionContentLoader() {
        let input = PlacementPopupInputMapper().map(
            makeModel(),
            overlayType: .singleProductOverlay,
            loadFollowUp: nil
        )

        guard case let .product(product) = input.content else {
            Issue.record("Expected product popup content")
            return
        }
        if case .some = product.loadActionContent {
            Issue.record("Expected no action content loader without a follow-up loader")
        }
    }

    @Test
    func malformedBodySectionKeyUsesZeroForOrdering() {
        let model = makeModel(
            bodyDiv: [
                "div1": .init(tagValuePairs: ["h3": "Numbered section"]),
                "invalid": .init(tagValuePairs: ["h3": "Fallback section"]),
            ]
        )
        let input = PlacementPopupInputMapper().map(
            model,
            overlayType: .singleProductOverlay,
            loadFollowUp: nil
        )

        guard case let .product(product) = input.content else {
            Issue.record("Expected product popup content")
            return
        }
        #expect(product.sections.map(\.text) == ["Fallback section", "Numbered section"])
    }

    private func makeModel(
        location: String? = "checkout",
        primaryActionButtonAttributes: PrimaryActionButtonModel? = nil,
        bodyDiv: [String: PopupPlacementModel.DynamicBodyContent] = [:]
    ) -> PopupPlacementModel {
        PopupPlacementModel(
            overlayType: "SINGLE_PRODUCT_OVERLAY",
            location: location,
            brandLogoUrl: "https://brand.test/logo.png",
            webViewUrl: "https://content.test",
            overlayTitle: NSAttributedString(string: "Offer title"),
            overlaySubtitle: NSAttributedString(string: "Offer subtitle"),
            overlayContainerBarHeading: NSAttributedString(string: "Offer heading"),
            bodyHeader: NSAttributedString(string: "Body heading"),
            primaryActionButtonAttributes: primaryActionButtonAttributes,
            dynamicBodyModel: PopupPlacementModel.DynamicBodyModel(bodyDiv: bodyDiv),
            disclosure: NSAttributedString(string: "Disclosure"),
            disclosureHTML: "<p>Disclosure</p>"
        )
    }
}
