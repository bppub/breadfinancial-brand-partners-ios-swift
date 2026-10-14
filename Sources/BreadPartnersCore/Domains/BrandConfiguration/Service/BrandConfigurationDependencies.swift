//------------------------------------------------------------------------------
//  File:          BrandConfigurationDependencies.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

package struct BrandConfigurationDependencies: Sendable {
    package let endpointProvider: any APIEndpointProviding
    package let responseDecoder: any BrandConfigurationResponseDecoding

    package init(
        endpointProvider: any APIEndpointProviding,
        responseDecoder: any BrandConfigurationResponseDecoding =
            LiveBrandConfigurationResponseDecoder()
    ) {
        self.endpointProvider = endpointProvider
        self.responseDecoder = responseDecoder
    }
}
