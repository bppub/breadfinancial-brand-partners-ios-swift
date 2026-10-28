//------------------------------------------------------------------------------
//  File:          LiveAPIEndpointProvider.swift
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

package struct LiveAPIEndpointProvider: APIEndpointProviding {
    private let environment: BreadPartnersEnvironment
    private let baseURLs: APIBaseURLs?

    package init(environment: BreadPartnersEnvironment, baseURLs: APIBaseURLs? = nil) {
        self.environment = environment
        self.baseURLs = baseURLs
    }

    package func url(for endpoint: APIEndpoint) -> URL {
        let urlString = endpoint.url(for: environment, baseURLs: baseURLs)

        guard let url = URL(string: urlString) else {
            preconditionFailure("APIEndpoint produced an invalid URL: \(urlString)")
        }

        return url
    }
}
