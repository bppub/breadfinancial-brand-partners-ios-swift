struct LiveBrandConfigurationServiceFactory: BrandConfigurationServiceFactory {
    private let endpointProvider: any APIEndpointProviding

    init(endpointProvider: any APIEndpointProviding) {
        self.endpointProvider = endpointProvider
    }

    func makeService(httpClient: any HTTPClient) -> any BrandConfigurationServicing {
        BrandConfigurationService(
            dependencies: BrandConfigurationDependencies(
                httpClient: httpClient,
                endpointProvider: endpointProvider,
                responseDecoder: LiveBrandConfigurationResponseDecoder()
            )
        )
    }
}
