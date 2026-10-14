//------------------------------------------------------------------------------
//  File:          RTPSOutcome.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

/// The result of a single RTPS workflow execution.
///
/// Callers own presentation and event translation; the service only reports what happened.
package enum RTPSOutcome: Sendable {
    /// Batch prescreen: skip the RTPS call and fetch placement data directly.
    case skipToPlacements
    /// Approved or account found with a usable prescreen id.
    case proceedToPlacements(RTPSResponse)
    /// A non-approved outcome that intentionally produces no user-visible behavior.
    case noAction
    case challenge(htmlContent: String, originalURL: String)
    case failure(RTPSServiceFailure)
}
