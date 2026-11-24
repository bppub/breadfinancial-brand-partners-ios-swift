//------------------------------------------------------------------------------
//  File:          HTMLLinkExtractorTests.swift
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

import BreadPartnersCore

@Suite
struct HTMLLinkExtractorTests {
    @Test
    func extractsAnchorsWithHrefAndText() {
        let html = """
            <p>See <a href="https://example.test/terms">terms</a> \
            and <a href="https://example.test/privacy">privacy</a></p>
            """

        let links = HTMLLinkExtractor().links(in: html)

        #expect(
            links == [
                .init(text: "terms", url: URL(string: "https://example.test/terms")!),
                .init(text: "privacy", url: URL(string: "https://example.test/privacy")!),
            ])
    }

    @Test
    func ignoresAnchorsWithoutHrefOrText() {
        let links = HTMLLinkExtractor().links(
            in: "<p><a>no href</a><a href=\"\">empty</a><a href=\"https://example.test\"></a></p>"
        )

        #expect(links.isEmpty)
    }

    @Test
    func usesTextOfNestedMarkupInsideAnchor() {
        let links = HTMLLinkExtractor().links(
            in: "<a href=\"https://example.test/apply\"><strong>Apply</strong> now</a>"
        )

        #expect(links == [.init(text: "Apply now", url: URL(string: "https://example.test/apply")!)])
    }

    @Test
    func skipsInvalidAnchorsAndKeepsValidOnesInDocumentOrder() {
        let html = """
            <a href="https://example.test/one">one</a>
            <a>missing href</a>
            <a href="https://example.test/two">two</a>
            """

        let links = HTMLLinkExtractor().links(in: html)

        #expect(links.map(\.text) == ["one", "two"])
    }

    @Test(arguments: ["", "plain text without markup"])
    func returnsNoLinksWhenThereAreNoAnchors(html: String) {
        #expect(HTMLLinkExtractor().links(in: html).isEmpty)
    }
}
