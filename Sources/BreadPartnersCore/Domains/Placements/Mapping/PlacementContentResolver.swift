//------------------------------------------------------------------------------
//  File:          PlacementContentResolver.swift
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

package enum PlacementContentResolutionError: Error, Equatable, Sendable {
    case missingTextContent
    case missingOverlayTemplate
    case missingActionContent(actionContentId: String?)
    case missingPopupFollowUpContent
}

package struct PlacementContentResolver: Sendable {
    package init() {}

    package func firstTextContent(in response: PlacementsResponse) throws -> PlacementContentModel {
        guard let content = response.placementContent?.first else {
            throw PlacementContentResolutionError.missingTextContent
        }
        return content
    }

    package func firstPopupFollowUpContent(in response: PlacementsResponse) throws -> PlacementContentModel {
        guard let content = response.placementContent?.first else {
            throw PlacementContentResolutionError.missingPopupFollowUpContent
        }
        return content
    }

    package func firstOverlayTemplate(in response: PlacementsResponse) throws -> PlacementContentModel {
        guard
            let content = response.placementContent?.first(where: {
                $0.metadata?.templateId?.contains("overlay") == true
            })
        else {
            throw PlacementContentResolutionError.missingOverlayTemplate
        }
        return content
    }

    package func actionContent(
        in response: PlacementsResponse,
        actionContentId: String?
    ) throws -> PlacementContentModel {
        guard
            let content = response.placementContent?.first(where: {
                $0.id == actionContentId
            })
        else {
            throw PlacementContentResolutionError.missingActionContent(actionContentId: actionContentId)
        }
        return content
    }
}
