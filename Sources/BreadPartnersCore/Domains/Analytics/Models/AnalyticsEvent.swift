//------------------------------------------------------------------------------
//  File:          AnalyticsEvent.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

package enum AnalyticsEvent: String, CaseIterable, Sendable {
    case viewPlacement = "view-placement"
    case clickPlacement = "click-placement"

    package var endpoint: APIEndpoint {
        switch self {
        case .viewPlacement: .viewPlacement
        case .clickPlacement: .clickPlacement
        }
    }
}
