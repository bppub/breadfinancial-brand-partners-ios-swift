//------------------------------------------------------------------------------
//  File:          APIBaseURLs.swift
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

package struct APIBaseURLs: Sendable, Equatable {
    package let brands: String
    package let rtps: String

    package init(brands: String, rtps: String) {
        self.brands = brands
        self.rtps = rtps
    }

    package static func live(for environment: BreadPartnersEnvironment) -> APIBaseURLs {
        let rtps: String

        switch environment {
        case .stage:
            rtps = "https://acquire1stage.comenity.net"
        case .prod:
            rtps = "https://acquire1.comenity.net"
        case .uat:
            rtps = "https://acquire1uat.comenity.net"
        }

        return APIBaseURLs(brands: "https://brands.kmsmep.com", rtps: rtps)
    }
}

extension APIBaseURLs {
    package static let launchOverrideKey = "BREAD_PARTNERS_MOCK_BASE_URL"

    private static let allowedOverrideHosts: Set<String> = ["localhost", "127.0.0.1"]

    // DEBUG-only and loopback-only so a shipped app can never be redirected.
    package static func launchOverride(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> APIBaseURLs? {
        #if DEBUG
            guard
                let raw = environment[launchOverrideKey],
                let url = URL(string: raw),
                url.scheme == "http" || url.scheme == "https",
                let host = url.host,
                allowedOverrideHosts.contains(host)
            else { return nil }

            let baseURL = raw.hasSuffix("/") ? String(raw.dropLast()) : raw
            return APIBaseURLs(brands: baseURL, rtps: baseURL)
        #else
            return nil
        #endif
    }
}
