import BreadPartnersCore
import Foundation

package struct LiveAPIEndpointProvider: APIEndpointProviding {
    private let environment: BreadPartnersEnvironment

    package init(environment: BreadPartnersEnvironment) {
        self.environment = environment
    }

    package func url(for endpoint: APIEndpoint) -> URL {
        // Temporarily delegating URL resolution to APIUrl for the given endpoint and environment.
        // This will be replaced with direct URL construction logic once all callers are consuming from here directly.
        APIUrl(
            urlType: apiUrlType(for: endpoint),
            environment: environment
        ).foundationURL
    }

    /// This mapping function goes away once `LiveAPIEndpointProvider` fully replaces `APIUrl` for URL resolution.
    private func apiUrlType(for endpoint: APIEndpoint) -> APIUrlType {
        switch endpoint {
        case let .rtpsWebUrl(type):
            return .rtpsWebUrl(type: type)
        case .bpsWebUrl:
            return .bpsWebUrl
        case let .brandStyle(brandId):
            return .brandStyle(brandId: brandId)
        case let .brandConfig(brandId):
            return .brandConfig(brandId: brandId)
        case .generatePlacements:
            return .generatePlacements
        case .viewPlacement:
            return .viewPlacement
        case .clickPlacement:
            return .clickPlacement
        case .prescreen:
            return .prescreen
        case .virtualLookup:
            return .virtualLookup
        }
    }
}
