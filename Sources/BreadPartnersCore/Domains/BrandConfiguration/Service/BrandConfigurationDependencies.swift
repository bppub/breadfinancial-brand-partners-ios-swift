package struct BrandConfigurationDependencies: Sendable {
    package let httpClient: any HTTPClient
    package let endpointProvider: any APIEndpointProviding
    package let responseDecoder: any BrandConfigurationResponseDecoding

    package init(
        httpClient: any HTTPClient,
        endpointProvider: any APIEndpointProviding,
        responseDecoder: any BrandConfigurationResponseDecoding
    ) {
        self.httpClient = httpClient
        self.endpointProvider = endpointProvider
        self.responseDecoder = responseDecoder
    }
}
