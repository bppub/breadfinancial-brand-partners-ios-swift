//------------------------------------------------------------------------------
//  File:          BrandConfigurationDependenciesTests.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Testing

@testable import BreadPartnersCore

@Suite
struct BrandConfigurationDependenciesTests {
    @Test
    func initializerKeepsEndpointProviderAndDefaultsLiveDecoder() {
        let endpointProvider = LiveAPIEndpointProvider(environment: .stage)
        let dependencies = BrandConfigurationDependencies(
            endpointProvider: endpointProvider
        )

        #expect(dependencies.endpointProvider is LiveAPIEndpointProvider)
        #expect(
            dependencies.responseDecoder is LiveBrandConfigurationResponseDecoder
        )
    }
}
