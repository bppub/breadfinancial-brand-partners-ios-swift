//------------------------------------------------------------------------------
//  File:          TextPlacementModel.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartnersSDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

/// Struct representing the model for text placements.
internal struct TextPlacementModel {
    let actionType: String?
    let actionTarget: String?
    let contentText: String?
    let actionLink: String?
    let actionContentId: String?
    let htmlContent: String?
}

/// Enum representing the different action types associated with a placement.
internal enum PlacementActionType: String {
    case showOverlay = "SHOW_OVERLAY"
    case redirect = "REDIRECT"
    case breadApply = "BREAD_APPLY"
    case redirectInternal = "REDIRECT_INTERNAL"
    case versatileEco = "VERSATILE_ECO"
    case noAction = "NO_ACTION"
}
