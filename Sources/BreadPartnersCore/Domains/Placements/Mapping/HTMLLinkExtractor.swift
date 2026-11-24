//------------------------------------------------------------------------------
//  File:          HTMLLinkExtractor.swift
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
import SwiftSoup

/// Extracts anchors that have a non-empty `href` and link text from an HTML fragment.
package struct HTMLLinkExtractor: Sendable {
    package struct Link: Equatable, Sendable {
        package let text: String
        package let url: URL

        package init(text: String, url: URL) {
            self.text = text
            self.url = url
        }
    }

    package init() {}

    package func links(in html: String) -> [Link] {
        guard let document = try? SwiftSoup.parse(html) else { return [] }
        let anchors = (try? document.select("a[href]").array()) ?? []
        return anchors.compactMap { anchor in
            guard
                let href = try? anchor.attr("href"),
                !href.isEmpty,
                let url = URL(string: href),
                let text = try? anchor.text(),
                !text.isEmpty
            else { return nil }
            return Link(text: text, url: url)
        }
    }
}
