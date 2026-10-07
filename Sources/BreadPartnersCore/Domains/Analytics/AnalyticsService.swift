//------------------------------------------------------------------------------
//  File:          AnalyticsService.swift
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

package struct AnalyticsService: Sendable {
    private let endpointProvider: any APIEndpointProviding

    package init(endpointProvider: any APIEndpointProviding) {
        self.endpointProvider = endpointProvider
    }

    package func send(
        event: AnalyticsEvent,
        httpClient: any HTTPClient,
        placementResponse: PlacementsResponse,
        timestamp: String,
        apiKey: String,
        userAgent: String?
    ) async {
        let payload = AnalyticsPayloadBuilder().build(
            name: event.rawValue, placementResponse: placementResponse,
            timestamp: timestamp, apiKey: apiKey, userAgent: userAgent
        )

        do {
            _ = try await httpClient.request(
                HTTPRequest(
                    url: endpointProvider.url(for: event.endpoint),
                    method: .OPTIONS,
                    headers: [
                        "authority": "metrics.kmsmep.com",
                        "Accept": "*/*",
                        "Accept-Encoding": "gzip, deflate, br, zstd",
                        "Accept-Language": "en-GB,en-US;q=0.9,en;q=0.8",
                        "Access-Control-Request-Headers": "content-type",
                        "Access-Control-Request-Method": "POST",
                    ],
                    body: try JSONEncoder().encode(payload)
                )
            )
        } catch {
        }
    }
}
