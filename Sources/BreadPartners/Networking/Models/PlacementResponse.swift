//------------------------------------------------------------------------------
//  File:          PlacementResponse.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartnersSDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

import Foundation

/// Represents the response containing placements.
internal struct PlacementsResponse: Codable {
    let placements: [PlacementsModel]?
    let placementContent: [PlacementContentModel]?
}

/// Represents individual placement details in the response.
internal struct PlacementsModel: Codable {
    let id: String?
    let content: PlacementContentReferenceModel?
    let renderContext: RenderContextModel?
}

internal struct PlacementContentReferenceModel: Codable {
    let contentId: String?
}

internal struct RenderContextModel: Codable {
    let LOCATION: String?
    let subchannel: String?
    let RTPS_ID: String?
    let PREQUAL_ID: String?
    let PRICE: Int?
    let DATETIME: String?
    let SDK_TID: String?
    let BUYER_ID: String?
    let channel: String?
    let PREQUAL_CREDIT_LIMIT: String?
    let ENV: String?
    let ALLOW_CHECKOUT: Bool?
    let embeddedUrl: String?
}

internal struct PlacementContentModel: Codable {
    let id: String?
    let contentType: String?
    let contentData: ContentDataModel?
    let metadata: MetadataModel?
}

internal struct ContentDataModel: Codable {
    let htmlContent: String?
}

internal struct MetadataModel: Codable {
    let placementId: String?
    let productType: String?
    let messageId: String?
    let templateId: String?
}
