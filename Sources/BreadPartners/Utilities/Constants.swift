//------------------------------------------------------------------------------
//  File:          Constants.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

internal class Constants {

    // API constants
    static let headerUserAgentKey = "User-Agent"
    static let headerContentType = "Content-Type"
    static let headerContentTypeValue = "application/json"
    static let headerOriginKey = "Origin"
    static let headerOriginValue = "https://brand-sdk.kmsmep.com"
    static let headerPlatformKey = "platform"
    static let headerPlatformValue = "ios"

    static let error = RTPSConstants.error

    static func apiError(message: String) -> String {
        RTPSConstants.apiError(message: message)
    }
    static let missingTextPlacementError = "Unhandled text placement type."
    static let noTextPlacementError = "No text placement type found."
    static let textPlacementParsingError = "Unable to parse text placement."

    static let popupPlacementParsingError = "\(error) Unable to parse popup placement."
    static let missingPopupPlacementError = "Unhandled popup placement type."
    static let somethingWentWrong = "Something went wrong. Please try again later."

    static let prescreenRequiredFieldsError = RTPSConstants.prescreenRequiredFieldsError

    static func unableToLoadWebURL(message: String) -> String {
        return "\(error) Web Url Loading Issue: \(message)"
    }

    // Confirm Navigation dialog (mirrors Android WebView onJsBeforeUnload system dialog)
    static let confirmNavigationTitle = "Confirm Navigation"
    static let confirmNavigationMessage =
        "Changes you made may not be saved.\n\nAre you sure you want to navigate away from this page?"
    static let confirmNavigationStayButton = "Stay"
    static let confirmNavigationLeaveButton = "Leave"
}
