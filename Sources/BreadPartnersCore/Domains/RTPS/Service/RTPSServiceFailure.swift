//------------------------------------------------------------------------------
//  File:          RTPSServiceFailure.swift
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

/// Typed failures returned by `RTPSService` so Core does not depend on SDK error strings or events.
package enum RTPSServiceFailure: Sendable {
    case missingRequiredFields
    case api(message: String)
    case underlying(NSError)
}
