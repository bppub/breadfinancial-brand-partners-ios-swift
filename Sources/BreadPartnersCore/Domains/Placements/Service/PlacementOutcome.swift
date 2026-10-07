//------------------------------------------------------------------------------
//  File:          PlacementOutcome.swift
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

package enum PlacementOutcome: Sendable {
    case success(PlacementsResponse)
    case challenge(htmlContent: String, originalURL: String, error: NSError)
    case failure(NSError)
}
