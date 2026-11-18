//------------------------------------------------------------------------------
//  File:          BreadPartnerLinkTextSwiftUITests.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import SwiftUI
import Testing
import UIKit
@testable import BreadPartners

@MainActor
struct BreadPartnerLinkTextSwiftUITests {
    @Test
    func fontResolutionUsesNamedFontOrSystemFallback() {
        let namedFont = breadPartnerLinkTextFontToUIFont(fontName: "Helvetica", size: 19)
        #expect(namedFont.fontName == "Helvetica")
        #expect(namedFont.pointSize == 19)

        let fallbackFont = breadPartnerLinkTextFontToUIFont(fontName: "Missing-Test-Font", size: 19)
        #expect(fallbackFont.isEqual(UIFont.systemFont(ofSize: 19)))
    }

    @Test
    func namedColorsMapToUIKitColors() {
        let colorMappings: [(Color, UIColor)] = [
            (.black, .black),
            (.white, .white),
            (.red, .red),
            (.green, .green),
            (.blue, .blue),
            (.gray, .gray),
            (.yellow, .yellow),
            (.orange, .orange),
            (.pink, .systemPink),
            (.purple, .purple),
        ]

        for (color, expectedColor) in colorMappings {
            #expect(breadPartnerLinkTextColorToUIColor(color).isEqual(expectedColor))
        }
    }

    @Test
    func customColorConvertsToUIKitColor() {
        let expectedColor = UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.5)

        #expect(breadPartnerLinkTextColorToUIColor(Color(uiColor: expectedColor)).isEqual(expectedColor))
    }

    @Test
    func plainTextUsesDefaultFontWithoutLinkStyling() {
        let view = BreadPartnerLinkTextSwiftUI("Plain text")
        let rendered = view.resolvedAttributedText

        #expect(rendered.string == "Plain text")
        for index in 0..<rendered.length {
            #expect(
                (rendered.attribute(.font, at: index, effectiveRange: nil) as? UIFont)
                    == UIFont.systemFont(ofSize: 17))
            #expect(rendered.attribute(.foregroundColor, at: index, effectiveRange: nil) == nil)
            #expect(rendered.attribute(.underlineStyle, at: index, effectiveRange: nil) == nil)
        }
        #expect(view.resolvedAccessibilityIdentifier == "Plain text")
    }

    @Test
    func matchingLinksReceiveDefaultStylingAndInitializerFont() {
        let view = BreadPartnerLinkTextSwiftUI(
            "Read terms and details", links: ["terms", "details"], fontName: "Helvetica", fontSize: 21
        )
        let rendered = view.resolvedAttributedText
        let font = UIFont(name: "Helvetica", size: 21)

        for index in 0..<rendered.length {
            #expect(rendered.attribute(.font, at: index, effectiveRange: nil) as? UIFont == font)
            let isLink =
                NSLocationInRange(index, NSRange(location: 5, length: 5))
                || NSLocationInRange(index, NSRange(location: 15, length: 7))
            #expect(
                (rendered.attribute(.foregroundColor, at: index, effectiveRange: nil) as? UIColor)
                    == (isLink ? UIColor.blue : nil))
            #expect(
                (rendered.attribute(.underlineStyle, at: index, effectiveRange: nil) as? Int)
                    == (isLink ? NSUnderlineStyle.single.rawValue : nil))
        }
    }

    @Test(arguments: [
        ("", ["missing"], []),
        ("hello", [], []),
        ("hello", ["missing", "HELLO"], []),
        ("terms terms", ["terms"], [NSRange(location: 0, length: 5)]),
        ("application", ["app"], [NSRange(location: 0, length: 3)]),
        (
            "🍞 café terms", ["café", "terms"],
            [
                NSRange(location: 3, length: 4), NSRange(location: 8, length: 5),
            ]
        ),
        ("terms", ["terms", "terms", "term"], [NSRange(location: 0, length: 5)]),
    ])
    func linkMatchingPreservesExistingRangeSemantics(
        text: String, links: [String], styledRanges: [NSRange]
    ) {
        let rendered = BreadPartnerLinkTextSwiftUI(text, links: links).resolvedAttributedText

        #expect(rendered.string == text)
        for index in 0..<rendered.length {
            let isLink = styledRanges.contains { NSLocationInRange(index, $0) }
            #expect(
                (rendered.attribute(.underlineStyle, at: index, effectiveRange: nil) as? Int)
                    == (isLink ? NSUnderlineStyle.single.rawValue : nil))
        }
    }

    @Test
    func chainedModifiersStyleOutputWithoutChangingOriginal() {
        let original = BreadPartnerLinkTextSwiftUI("Read terms", links: ["terms"])
        let styled =
            original
            .linkColor(.red)
            .linkFont("Helvetica", fontSize: 24)
            .accessibilityIdentifier("custom-link")
        let rendered = styled.resolvedAttributedText

        #expect(rendered.attribute(.foregroundColor, at: 5, effectiveRange: nil) as? UIColor == .red)
        #expect(
            rendered.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
                == UIFont(name: "Helvetica", size: 24))
        #expect(
            rendered.attribute(.font, at: 5, effectiveRange: nil) as? UIFont
                == UIFont(name: "Helvetica", size: 24))
        #expect(styled.resolvedAccessibilityIdentifier == "custom-link")

        let unchanged = original.resolvedAttributedText
        #expect(unchanged.attribute(.foregroundColor, at: 5, effectiveRange: nil) as? UIColor == .blue)
        #expect(
            unchanged.attribute(.font, at: 5, effectiveRange: nil) as? UIFont
                == UIFont.systemFont(ofSize: 17))
        #expect(original.resolvedAccessibilityIdentifier == "Read terms")

        let fallback = styled.linkFont("Missing-Test-Font", fontSize: 22).resolvedAttributedText
        #expect(
            fallback.attribute(.font, at: 5, effectiveRange: nil) as? UIFont
                == UIFont.systemFont(ofSize: 22))
    }

    @Test(arguments: ["", "Custom accessibility ID"])
    func explicitAccessibilityIdentifierOverridesText(identifier: String) {
        let view = BreadPartnerLinkTextSwiftUI("Visible text").accessibilityIdentifier(identifier)
        #expect(view.resolvedAccessibilityIdentifier == identifier)
        #expect(view.resolvedAttributedText.string == "Visible text")
    }

    @Test
    func attributedInitializerPreservesFormattingDespiteStyleModifiers() {
        let attributed = NSAttributedString(
            string: "Formatted terms",
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: 23),
                .foregroundColor: UIColor.purple,
                .underlineStyle: NSUnderlineStyle.double.rawValue,
                .link: URL(string: "https://example.com/terms")!,
            ]
        )
        let view = BreadPartnerLinkTextSwiftUI(attributedString: attributed)
            .linkColor(.red)
            .linkFont("Helvetica", fontSize: 12)

        #expect(view.resolvedAttributedText.isEqual(to: attributed))
        #expect(view.resolvedAccessibilityIdentifier == attributed.string)
        #expect(
            BreadPartnerLinkTextSwiftUI(attributedString: NSAttributedString(string: ""))
                .resolvedAttributedText.length == 0)
    }

    @Test(arguments: [false, true])
    func coordinatorForwardsEveryTapAndAcceptsMissingHandler(hasHandler: Bool) {
        var tapCount = 0
        let representable = BreadPartnerLinkTextSwiftUI.UILabelRepresentable(
            attributedText: NSAttributedString(string: "Link"),
            onTap: hasHandler ? { tapCount += 1 } : nil
        )
        let coordinator = representable.makeCoordinator()

        coordinator.handleTap()
        coordinator.handleTap()
        #expect(tapCount == (hasHandler ? 2 : 0))
    }

}
