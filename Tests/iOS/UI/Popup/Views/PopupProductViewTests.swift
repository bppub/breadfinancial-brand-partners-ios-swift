//------------------------------------------------------------------------------
//  File:          PopupProductViewTests.swift
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
struct PopupProductViewTests {
    @Test
    func rendersProductContentAndConfiguresAction() throws {
        let input = makeInput(
            header: "Highlights",
            sections: [
                PopupBodySection(tag: "h3", text: "Cash back"),
                PopupBodySection(tag: "p", text: "Details"),
                PopupBodySection(tag: "connector", text: "or"),
                PopupBodySection(tag: "footer", text: "Terms apply"),
                PopupBodySection(tag: "unsupported", text: "Ignored"),
            ]
        )
        var actionCount = 0
        let view = try makeView(from: input) {
            actionCount += 1
        }
        let actions =
            view.actionButton.actions(
                forTarget: view,
                forControlEvent: .touchUpInside
            ) ?? []

        #expect(view.titleLabel.attributedText?.string == "Your offer")
        #expect(view.subtitleLabel.attributedText?.string == "Offer details")
        #expect(view.disclosureTextView.text == "Terms apply")
        #expect(view.sectionStackView.arrangedSubviews.count == 4)
        #expect(!view.detailsView.isHidden)
        #expect(!view.headerView.isHidden)
        #expect(view.actionButton.title(for: .normal) == "Continue")
        #expect(actions == ["actionButtonTapped:"])

        view.perform(NSSelectorFromString("actionButtonTapped:"), with: view.actionButton)

        #expect(actionCount == 1)
    }

    @Test
    func hidesDetailsCardWhenThereAreNoSections() throws {
        let input = makeInput(header: "", sections: [])
        let view = try makeView(from: input, onAction: {})

        #expect(view.detailsView.isHidden)
        #expect(view.headerView.isHidden)
        #expect(view.sectionStackView.arrangedSubviews.isEmpty)
    }

    @Test
    func disclosureAnchorReturnsToTop() throws {
        let input = makeInput(header: "", sections: [])
        let view = try makeView(from: input, onAction: {})
        view.scrollView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        view.scrollView.contentSize = CGSize(width: 100, height: 200)
        view.scrollView.setContentOffset(CGPoint(x: 0, y: 80), animated: false)
        let anchor = try #require(URL(string: "#epjs-css-overlay-header"))

        let shouldOpen = view.textView(
            view.disclosureTextView,
            shouldInteractWith: anchor,
            in: NSRange(location: 0, length: 1),
            interaction: .invokeDefaultAction
        )

        #expect(!shouldOpen)
        #expect(view.scrollView.contentOffset == .zero)
    }

    @Test
    func nonAnchorDisclosureLinksAreAllowed() throws {
        let input = makeInput(header: "", sections: [])
        let view = try makeView(from: input, onAction: {})
        let url = try #require(URL(string: "https://example.test/terms"))

        let shouldOpen = view.textView(
            view.disclosureTextView,
            shouldInteractWith: url,
            in: NSRange(location: 0, length: 1),
            interaction: .invokeDefaultAction
        )

        #expect(shouldOpen)
    }

    private func makeInput(
        header: String,
        sections: [PopupBodySection]
    ) -> PopupInput {
        .product(
            style: PopUpStyling(),
            logoURL: "",
            title: NSAttributedString(string: "Your offer"),
            subtitle: NSAttributedString(string: "Offer details"),
            header: NSAttributedString(string: header),
            sections: sections,
            disclosure: NSAttributedString(string: "Terms apply"),
            disclosureHTML: "",
            actionTitle: "Continue"
        )
    }

    private func makeView(
        from input: PopupInput,
        onAction: @escaping () -> Void
    ) throws -> PopupProductView {
        let productContent = try #require(product(in: input))
        let presentation = PopupProductPresentationMapper().map(
            product: productContent,
            style: input.style
        )
        return PopupProductView(presentation: presentation, onAction: onAction)
    }

    private func product(in input: PopupInput) -> PopupInput.Product? {
        guard case let .product(product) = input.content else { return nil }
        return product
    }
}
