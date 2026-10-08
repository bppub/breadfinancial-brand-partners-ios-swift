//------------------------------------------------------------------------------
//  File:          HTMLContentParser.swift
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

/// Actor responsible for extracting structured data from HTML using SwiftSoup.
internal actor HTMLContentParser {

    func extractPopupPlacementModel(from htmlContent: String) async throws
        -> PopupPlacementModel?
    {
        return PopupPlacementModelMapper().map(
            try PopupPlacementHTMLParser().extract(htmlContent: htmlContent)
        )
    }

    func handleActionType(from response: String) -> PlacementActionType? {
        return PlacementActionType(rawValue: response)
    }

    func handleOverlayType(from response: String) -> PlacementOverlayType? {
        return PlacementOverlayType(rawValue: response)
    }
}
