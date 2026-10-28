//------------------------------------------------------------------------------
//  File:          LiveAPIEndpointProviderTests.swift
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
import Testing

@testable import BreadPartnersCore

@Suite
struct LiveAPIEndpointProviderTests {
    @Test
    func resolvesEndpointsForEachEnvironment() {
        let environments: [(BreadPartnersEnvironment, String, String)] = [
            (.stage, "https://brands.kmsmep.com", "https://acquire1stage.comenity.net"),
            (.prod, "https://brands.kmsmep.com", "https://acquire1.comenity.net"),
            (.uat, "https://brands.kmsmep.com", "https://acquire1uat.comenity.net"),
        ]

        for (environment, baseURL, rtpsBaseURL) in environments {
            let provider = LiveAPIEndpointProvider(environment: environment)

            let expectedURLs: [(APIEndpoint, String)] = [
                (.rtpsWebUrl(type: "lookup"), "\(rtpsBaseURL)/prescreen/lookup"),
                (.bpsWebUrl, "\(rtpsBaseURL)/batch-prescreen/start"),
                (.brandStyle(brandId: "brand-123"), "\(baseURL)/brands/brand-123/style"),
                (.brandConfig(brandId: "brand-123"), "\(baseURL)/brands/brand-123/config"),
                (.generatePlacements, "\(baseURL)/generatePlacements"),
                (.viewPlacement, "\(baseURL)/ep/v1/view-placement"),
                (.clickPlacement, "\(baseURL)/ep/v1/click-placement"),
                (.prescreen, "\(rtpsBaseURL)/api/prescreen"),
                (.virtualLookup, "\(rtpsBaseURL)/api/virtual_lookup"),
            ]

            for (endpoint, expectedURL) in expectedURLs {
                #expect(provider.url(for: endpoint) == URL(string: expectedURL))
            }
        }
    }

    @Test
    func resolvesEndpointsAgainstBaseURLOverride() {
        let provider = LiveAPIEndpointProvider(
            environment: .prod,
            baseURLs: APIBaseURLs(brands: "http://localhost:8080", rtps: "http://localhost:8080")
        )

        #expect(
            provider.url(for: .brandConfig(brandId: "brand-123"))
                == URL(string: "http://localhost:8080/brands/brand-123/config")
        )
        #expect(
            provider.url(for: .virtualLookup)
                == URL(string: "http://localhost:8080/api/virtual_lookup")
        )
    }
}
