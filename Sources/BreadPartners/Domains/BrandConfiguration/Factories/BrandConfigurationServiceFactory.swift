import BreadPartnersCore

protocol BrandConfigurationServiceFactory: Sendable {
    func makeService(httpClient: any HTTPClient) -> any BrandConfigurationServicing
}

struct LiveBrandConfigurationServiceFactory: BrandConfigurationServiceFactory {
    private let endpointProvider: any APIEndpointProviding

    init(endpointProvider: any APIEndpointProviding) {
        self.endpointProvider = endpointProvider
    }

    func makeService(httpClient: any HTTPClient) -> any BrandConfigurationServicing {
        LiveBrandConfigurationService(
            httpClient: httpClient,
            endpointProvider: endpointProvider
        )
    }
}
