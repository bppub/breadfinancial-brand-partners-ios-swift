//------------------------------------------------------------------------------
//  File:          PopupInputTests.swift
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
import UIKit
@testable import BreadPartners

@Suite
@MainActor
struct PopupInputTests {
    @Test
    func embeddedFactoryPreservesValuesAndDefaultsCloseButtonToVisible() throws {
        let style = PopUpStyling()
        let input = PopupInput.embedded(
            style: style,
            logoURL: "https://example.test/logo.png",
            webViewURL: "https://example.test/offer"
        )

        #expect(input.style.loaderColor == style.loaderColor)
        #expect(input.content.isEmbedded)
        #expect(input.chromeConfiguration.logoURL == "https://example.test/logo.png")
        #expect(input.chromeConfiguration.showsCloseButton)
        guard case let .embedded(content) = input.content else {
            Issue.record("Expected embedded popup content")
            return
        }
        #expect(content.logoURL == "https://example.test/logo.png")
        #expect(content.webViewURL == "https://example.test/offer")
        #expect(content.showsCloseButton)
    }

    @Test
    func embeddedFactoryCanHideCloseButton() throws {
        let input = PopupInput.embedded(
            style: PopUpStyling(),
            logoURL: "logo.png",
            webViewURL: "https://example.test/offer",
            showsCloseButton: false
        )

        guard case let .embedded(content) = input.content else {
            Issue.record("Expected embedded popup content")
            return
        }
        #expect(!content.showsCloseButton)
    }

    @Test
    func productFactoryPreservesValuesAndOptionalDefaults() throws {
        let style = PopUpStyling()
        let title = NSAttributedString(string: "Offer")
        let subtitle = NSAttributedString(string: "Details")
        let header = NSAttributedString(string: "Highlights")
        let disclosure = NSAttributedString(string: "Terms apply")
        let sections = [PopupBodySection(tag: "h3", text: "Cash back")]
        let input = PopupInput.product(
            style: style,
            logoURL: "https://example.test/logo.png",
            title: title,
            subtitle: subtitle,
            header: header,
            sections: sections,
            disclosure: disclosure,
            disclosureHTML: "<p>Terms apply</p>",
            actionTitle: "Continue"
        )

        #expect(!input.content.isEmbedded)
        #expect(input.chromeConfiguration.logoURL == "https://example.test/logo.png")
        #expect(input.chromeConfiguration.showsCloseButton)
        #expect(input.style.loaderColor == style.loaderColor)
        guard case let .product(product) = input.content else {
            Issue.record("Expected product popup content")
            return
        }
        #expect(product.logoURL == "https://example.test/logo.png")
        #expect(product.title.string == "Offer")
        #expect(product.subtitle.string == "Details")
        #expect(product.header.string == "Highlights")
        #expect(product.sections.map(\.tag) == ["h3"])
        #expect(product.sections.map(\.text) == ["Cash back"])
        #expect(product.disclosure.string == "Terms apply")
        #expect(product.disclosureHTML == "<p>Terms apply</p>")
        #expect(product.actionTitle == "Continue")
        #expect(product.showsCloseButton)
        #expect(product.actionPlacementID == nil)
        #expect(product.loadActionContent == nil)
    }

    @Test
    func productFactoryStoresPlacementIDAndFollowUpLoader() async throws {
        let followUp = PopupInput.Embedded(
            logoURL: "https://example.test/follow-up-logo.png",
            webViewURL: "https://example.test/follow-up",
            showsCloseButton: false
        )
        let input = PopupInput.product(
            style: PopUpStyling(),
            logoURL: "",
            title: NSAttributedString(string: "Offer"),
            subtitle: NSAttributedString(string: ""),
            header: NSAttributedString(string: ""),
            sections: [],
            disclosure: NSAttributedString(string: ""),
            disclosureHTML: "",
            actionTitle: "Continue",
            showsCloseButton: false,
            actionPlacementID: "follow-up-id",
            loadActionContent: { placementID in
                guard placementID == "follow-up-id" else { return nil }
                return followUp
            }
        )

        guard case let .product(product) = input.content else {
            Issue.record("Expected product popup content")
            return
        }
        let loader = try #require(product.loadActionContent)
        let loadedContent = try await loader(product.actionPlacementID)

        #expect(!product.showsCloseButton)
        #expect(product.actionPlacementID == "follow-up-id")
        #expect(loadedContent?.webViewURL == "https://example.test/follow-up")
        #expect(loadedContent?.showsCloseButton == false)
    }
}
