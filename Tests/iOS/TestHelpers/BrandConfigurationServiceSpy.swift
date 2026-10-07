//------------------------------------------------------------------------------
//  File:          BrandConfigurationServiceSpy.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import BreadPartnersCore

actor BrandConfigurationServiceSpy: BrandConfigurationServicing {
    private var results: [BrandConfiguration?]
    private(set) var requestedBrandIDs: [String] = []

    init(results: [BrandConfiguration?]) {
        self.results = results
    }

    package func fetch(
        brandID: String,
        httpClient: any HTTPClient
    ) async -> BrandConfiguration? {
        requestedBrandIDs.append(brandID)
        guard !results.isEmpty else { return nil }
        return results.removeFirst()
    }
}
