//------------------------------------------------------------------------------
//  File:          APIUrl.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

import Foundation

/// Enum to define different types of API URLs.
internal enum APIUrlType {
    case rtpsWebUrl(type: String)
    case bpsWebUrl
    case brandStyle(brandId: String)
    case brandConfig(brandId: String)
    case generatePlacements
    case viewPlacement
    case clickPlacement
    case prescreen
    case virtualLookup
}

@available(*, deprecated, message: "Use `LiveAPIEndpointProvider` instead for resolving API URLs.")
internal actor APIUrl {
    nonisolated(unsafe) static var currentEnvironment: BreadPartnersEnvironment = .prod

    private let environment: BreadPartnersEnvironment
    private let urlType: APIUrlType

    /// Adding a transitional environment handler to allow for testing of the current behavior.
    /// In future updates, this will become a core SDK Dependency and current/setEnvironment will go away
    /// in favor of direct initialization. The current implementation is not testable in isolation.
    init(
        urlType: APIUrlType,
        environment: BreadPartnersEnvironment? = nil
    ) {
        self.urlType = urlType
        self.environment = environment ?? APIUrl.currentEnvironment
    }

    /// Set the environment
    static func setEnvironment(_ environment: BreadPartnersEnvironment) async {
        currentEnvironment = environment
    }

    /// Generates the correct URL based on the URL type
    nonisolated var url: String {
        let endpoint: APIEndpoint

        switch urlType {
        case .rtpsWebUrl(let type):
            endpoint = .rtpsWebUrl(type: type)
        case .bpsWebUrl:
            endpoint = .bpsWebUrl
        case .brandStyle(let brandId):
            endpoint = .brandStyle(brandId: brandId)
        case .brandConfig(let brandId):
            endpoint = .brandConfig(brandId: brandId)
        case .generatePlacements:
            endpoint = .generatePlacements
        case .viewPlacement:
            endpoint = .viewPlacement
        case .clickPlacement:
            endpoint = .clickPlacement
        case .prescreen:
            endpoint = .prescreen
        case .virtualLookup:
            endpoint = .virtualLookup
        }

        return endpoint.url(for: environment)
    }

    nonisolated var foundationURL: URL {
        // This guard is not unit-testabile as it only fails with invalid configuration.
        guard let url = URL(string: url) else {
            preconditionFailure("APIUrl produced an invalid URL: \(url)")
        }

        return url
    }
}
