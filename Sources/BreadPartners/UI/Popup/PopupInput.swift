//------------------------------------------------------------------------------
//  File:          PopupInput.swift
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

struct PopupInput: @unchecked Sendable {
    enum Content: @unchecked Sendable {
        case embedded(Embedded)
        case product(Product)
    }

    struct Embedded: @unchecked Sendable {
        let logoURL: String
        let webViewURL: String
        let showsCloseButton: Bool
    }

    struct Product: @unchecked Sendable {
        let logoURL: String
        let title: NSAttributedString
        let subtitle: NSAttributedString
        let header: NSAttributedString
        let sections: [PopupBodySection]
        let disclosure: NSAttributedString
        let disclosureHTML: String
        let actionTitle: String
        let showsCloseButton: Bool
        let actionPlacementID: String?
        let loadActionContent: (@MainActor @Sendable (String?) async throws -> Embedded?)?
    }

    let style: PopUpStyling
    let content: Content

    static func embedded(
        style: PopUpStyling,
        logoURL: String,
        webViewURL: String,
        showsCloseButton: Bool = true
    ) -> Self {
        Self(
            style: style,
            content: .embedded(
                Embedded(
                    logoURL: logoURL,
                    webViewURL: webViewURL,
                    showsCloseButton: showsCloseButton
                )
            )
        )
    }

    static func product(
        style: PopUpStyling,
        logoURL: String,
        title: NSAttributedString,
        subtitle: NSAttributedString,
        header: NSAttributedString,
        sections: [PopupBodySection],
        disclosure: NSAttributedString,
        disclosureHTML: String,
        actionTitle: String,
        showsCloseButton: Bool = true,
        actionPlacementID: String? = nil,
        loadActionContent: (@MainActor @Sendable (String?) async throws -> Embedded?)? = nil
    ) -> Self {
        Self(
            style: style,
            content: .product(
                Product(
                    logoURL: logoURL,
                    title: title,
                    subtitle: subtitle,
                    header: header,
                    sections: sections,
                    disclosure: disclosure,
                    disclosureHTML: disclosureHTML,
                    actionTitle: actionTitle,
                    showsCloseButton: showsCloseButton,
                    actionPlacementID: actionPlacementID,
                    loadActionContent: loadActionContent
                )
            )
        )
    }
}

struct PopupBodySection: Sendable {
    let tag: String
    let text: String
}
