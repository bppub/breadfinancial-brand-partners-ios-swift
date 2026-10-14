//------------------------------------------------------------------------------
//  File:          PlacementService.swift
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

package struct PlacementService: Sendable {
    package init() {}

    package func execute(_ input: PlacementServiceInput) async -> PlacementOutcome {
        do {
            let data = try await input.httpClient.request(
                HTTPRequest(
                    url: input.url,
                    method: .POST,
                    cookies: input.cookies,
                    body: try JSONEncoder().encode(input.request)
                )
            )

            return .success(try JSONDecoder().decode(PlacementsResponse.self, from: data))
        } catch let error as NSError {
            guard error.domain == NetworkChallengeConstants.domain,
                let htmlContent = error.userInfo[NetworkChallengeConstants.htmlContentKey] as? String,
                let originalURL = error.userInfo[NetworkChallengeConstants.urlKey] as? String
            else {
                return .failure(error)
            }

            return .challenge(htmlContent: htmlContent, originalURL: originalURL, error: error)
        }
    }
}
