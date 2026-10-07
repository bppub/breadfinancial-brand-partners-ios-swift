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

    package init(environment: BreadPartnersEnvironment) {
        self.environment = environment
    }

    package func url(for endpoint: APIEndpoint) -> URL {
        let urlString = endpoint.url(for: environment)

        guard let url = URL(string: urlString) else {
            preconditionFailure("APIEndpoint produced an invalid URL: \(urlString)")
        }

        return url
    }
}
