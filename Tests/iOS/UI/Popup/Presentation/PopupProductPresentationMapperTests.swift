//------------------------------------------------------------------------------
//  File:          PopupProductPresentationMapperTests.swift
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
struct PopupProductPresentationMapperTests {
    @Test
    func mapsSupportedSectionsAndAppliesTextStyles() throws {
        let titleStyle = PopupTextStyle(
            font: .boldSystemFont(ofSize: 20),
            textColor: .systemRed
        )
        let headingStyle = PopupTextStyle(font: .systemFont(ofSize: 14), textColor: .systemBlue)
        let paragraphStyle = PopupTextStyle(textColor: .systemGreen)
        let connectorStyle = PopupTextStyle(textColor: .systemOrange)
        let style = PopUpStyling(
            titlePopupTextStyle: titleStyle,
            headingThreePopupTextStyle: headingStyle,
            paragraphPopupTextStyle: paragraphStyle,
            connectorPopupTextStyle: connectorStyle
        )
        let richTitle = NSAttributedString(
            string: "Offer",
            attributes: [.font: UIFont.italicSystemFont(ofSize: 12)]
        )
        let input = makeInput(
            style: style,
            title: richTitle,
            sections: [
                PopupBodySection(tag: "h3", text: "Highlights"),
                PopupBodySection(tag: "p", text: "Details"),
                PopupBodySection(tag: "connector", text: "or"),
                PopupBodySection(tag: "footer", text: "Terms"),
                PopupBodySection(tag: "unsupported", text: "Ignore"),
            ]
        )
        let presentation = PopupProductPresentationMapper().map(
            product: try #require(product(in: input)),
            style: style
        )
        let titleFont = try #require(
            presentation.title.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        )
        let headingFont = try #require(
            presentation.sections[0].text.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        )

        #expect(presentation.title.string == "Offer")
        #expect(titleFont.pointSize == 20)
        #expect(titleFont.fontDescriptor.symbolicTraits.contains(.traitBold))
        #expect(titleFont.fontDescriptor.symbolicTraits.contains(.traitItalic))
        #expect(
            presentation.title.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
                == .systemRed
        )
        #expect(presentation.sections.map(\.text.string) == ["Highlights", "Details", "or", "Terms"])
        #expect(
            presentation.sections.map {
                $0.text.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
            } == [.systemBlue, .systemGreen, .systemOrange, .systemGreen]
        )
        #expect(headingFont.pointSize == 14)
        #expect(presentation.showsDetailsCard)
    }

    @Test
    func mapsDisclosureHTMLLinksToAttributedText() throws {
        let style = PopUpStyling(
            disclosurePopupTextStyle: PopupTextStyle(textColor: .systemPurple)
        )
        let input = makeInput(
            style: style,
            disclosure: NSAttributedString(string: "Review the terms"),
            disclosureHTML: "<p>Review the <a href=\"https://example.test/terms\">terms</a></p>"
        )
        let presentation = PopupProductPresentationMapper().map(
            product: try #require(product(in: input)),
            style: style
        )
        let linkRange = (presentation.disclosure.string as NSString).range(of: "terms")
        let link = try #require(
            presentation.disclosure.attribute(.link, at: linkRange.location, effectiveRange: nil) as? URL
        )

        #expect(link.absoluteString == "https://example.test/terms")
        #expect(
            presentation.disclosure.attribute(.foregroundColor, at: linkRange.location, effectiveRange: nil)
                as? UIColor == .systemPurple
        )
    }

    @Test
    func disclosureHTMLWithoutHrefAnchorsRemainsUnlinked() throws {
        let input = makeInput(
            disclosure: NSAttributedString(string: "Review the terms"),
            disclosureHTML: "<p>Review <a>the terms</a></p>"
        )
        let presentation = PopupProductPresentationMapper().map(
            product: try #require(product(in: input)),
            style: input.style
        )
        let location = (presentation.disclosure.string as NSString).range(of: "terms").location

        #expect(location != NSNotFound)
        #expect(presentation.disclosure.attribute(.link, at: location, effectiveRange: nil) == nil)
    }

    @Test
    func skipsInvalidEmptyAndUnmatchedDisclosureAnchors() throws {
        let input = makeInput(
            disclosure: NSAttributedString(string: "Empty Invalid Bare Available"),
            disclosureHTML: """
                <a href="">Empty</a>
                <a href="http://[">Invalid</a>
                <a href="https://example.test/bare"></a>
                <a href="https://example.test/missing">Not present</a>
                <a href="https://example.test/available">Available</a>
                """
        )
        let presentation = PopupProductPresentationMapper().map(
            product: try #require(product(in: input)),
            style: input.style
        )
        let text = presentation.disclosure.string as NSString

        for value in ["Empty", "Invalid", "Bare"] {
            let location = text.range(of: value).location
            #expect(location != NSNotFound)
            #expect(presentation.disclosure.attribute(.link, at: location, effectiveRange: nil) == nil)
        }

        let availableLocation = text.range(of: "Available").location
        let link = try #require(
            presentation.disclosure.attribute(.link, at: availableLocation, effectiveRange: nil) as? URL
        )
        #expect(link.absoluteString == "https://example.test/available")
    }

    @Test
    func leavesEmptyTextUnmodifiedAndCentersExistingParagraphStyle() throws {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        let input = makeInput(
            style: PopUpStyling(
                titlePopupTextStyle: PopupTextStyle(font: .boldSystemFont(ofSize: 18))
            ),
            title: NSAttributedString(
                string: "Offer",
                attributes: [.paragraphStyle: paragraphStyle]
            ),
            subtitle: NSAttributedString(string: ""),
            disclosure: NSAttributedString(string: ""),
            disclosureHTML: "<a href=\"https://example.test/terms\">Terms</a>"
        )
        let presentation = PopupProductPresentationMapper().map(
            product: try #require(product(in: input)),
            style: input.style
        )
        let paragraph = try #require(
            presentation.title.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
        )

        #expect(paragraph.alignment == .center)
        #expect(presentation.title.attribute(.font, at: 0, effectiveRange: nil) != nil)
        #expect(presentation.subtitle.length == 0)
        #expect(presentation.disclosure.length == 0)
    }

    @Test
    func fallsBackToTargetFontWhenCombinedDescriptorIsUnavailable() {
        let targetFont = UIFont.systemFont(ofSize: 18)
        let resolvedFont = PopupProductPresentationMapper().resolvedFont(
            targetFont: targetFont,
            descriptor: nil
        )

        #expect(resolvedFont === targetFont)
    }

    @Test
    func hidesDetailsCardWhenProductHasNoSections() throws {
        let input = makeInput(sections: [])
        let presentation = PopupProductPresentationMapper().map(
            product: try #require(product(in: input)),
            style: input.style
        )

        #expect(presentation.sections.isEmpty)
        #expect(!presentation.showsDetailsCard)
    }

    private func makeInput(
        style: PopUpStyling = PopUpStyling(),
        title: NSAttributedString = NSAttributedString(string: "Offer"),
        subtitle: NSAttributedString = NSAttributedString(string: "Details"),
        sections: [PopupBodySection] = [],
        disclosure: NSAttributedString = NSAttributedString(string: "Terms apply"),
        disclosureHTML: String = ""
    ) -> PopupInput {
        .product(
            style: style,
            logoURL: "",
            title: title,
            subtitle: subtitle,
            header: NSAttributedString(string: "Highlights"),
            sections: sections,
            disclosure: disclosure,
            disclosureHTML: disclosureHTML,
            actionTitle: "Continue"
        )
    }

    private func product(in input: PopupInput) -> PopupInput.Product? {
        guard case let .product(product) = input.content else { return nil }
        return product
    }
}
