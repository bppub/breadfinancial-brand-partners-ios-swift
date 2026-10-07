//------------------------------------------------------------------------------
//  File:          LivePlacementService.swift
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
import Foundation

struct LivePlacementService: PlacementServicing {
    func fetch(
        request: PlacementRequest,
        from url: URL,
        httpClient: any HTTPClient
    ) async throws -> PlacementsResponse {
        let data = try await httpClient.request(
            HTTPRequest(
                url: url,
                method: .POST,
                body: try JSONEncoder().encode(request)
            )
        )

        return try JSONDecoder().decode(PlacementsResponse.self, from: data)
    }
}
