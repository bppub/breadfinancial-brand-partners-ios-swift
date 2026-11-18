//------------------------------------------------------------------------------
//  File:          BreadPartnerLinkTextTests.swift
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
struct BreadPartnerLinkTextTests {
    @Test
    func setupCreatesNonEditableSelectableTextView() {
        let textView = BreadPartnerLinkText()

        #expect(!textView.isEditable)
        #expect(!textView.isScrollEnabled)
        #expect(textView.isSelectable)
        #expect(textView.backgroundColor == .clear)
        #expect(textView.dataDetectorTypes == .link)
        #expect(textView.gestureRecognizers?.contains { $0 is UITapGestureRecognizer } == true)
    }

    @Test
    func configureStoresTextAndLinkHandler() throws {
        let textView = BreadPartnerLinkText()
        let attributedText = NSAttributedString(
            string: "Terms",
            attributes: [.link: "https://example.test/terms"]
        )
        var receivedLink: String?

        textView.configure(with: attributedText) { receivedLink = $0 }
        textView.tapHandler?("https://example.test/terms")

        #expect(textView.attributedText.isEqual(to: attributedText))
        #expect(receivedLink == "https://example.test/terms")
    }

    @Test
    func configureWithoutLinkDefaultsToTapAnywhere() async throws {
        let textView = BreadPartnerLinkText()
        let attributedText = NSAttributedString(string: "No action")
        var receivedLink: String?

        textView.configure(with: attributedText) { receivedLink = $0 }
        textView.tapHandler?("")

        #expect(textView.attributedText.isEqual(to: attributedText))
        #expect(receivedLink == "")
    }

    @Test
    func configureAcceptsMissingHandler() {
        let textView = BreadPartnerLinkText()
        let attributedText = NSAttributedString(string: "Plain")

        textView.configure(with: attributedText)

        #expect(textView.tapHandler == nil)
        #expect(textView.attributedText.isEqual(to: attributedText))
    }
}
