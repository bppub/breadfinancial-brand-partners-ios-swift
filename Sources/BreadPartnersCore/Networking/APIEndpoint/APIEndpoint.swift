//------------------------------------------------------------------------------
//  File:          APIEndpoint.swift
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

package enum APIEndpoint: Sendable {
    case rtpsWebUrl(type: String)
    case bpsWebUrl
    case brandStyle(brandId: String)
    case brandConfig(brandId: String)
    case generatePlacements
    case viewPlacement
    case clickPlacement
    case prescreen
    case virtualLookup

    package func url(
        for environment: BreadPartnersEnvironment,
        baseURLs override: APIBaseURLs? = nil
    ) -> String {
        let baseURLs = override ?? .live(for: environment)
        let baseURL = baseURLs.brands
        let rtpsBaseURL = baseURLs.rtps

        switch self {
        case let .rtpsWebUrl(type):
            return "\(rtpsBaseURL)/prescreen/\(type)"
        case .bpsWebUrl:
            return "\(rtpsBaseURL)/batch-prescreen/start"
        case let .brandStyle(brandId):
            return "\(baseURL)/brands/\(brandId)/style"
        case let .brandConfig(brandId):
            return "\(baseURL)/brands/\(brandId)/config"
        case .generatePlacements:
            return "\(baseURL)/generatePlacements"
        case .viewPlacement:
            return "\(baseURL)/ep/v1/view-placement"
        case .clickPlacement:
            return "\(baseURL)/ep/v1/click-placement"
        case .prescreen:
            return "\(rtpsBaseURL)/api/prescreen"
        case .virtualLookup:
            return "\(rtpsBaseURL)/api/virtual_lookup"
        }
    }
}
