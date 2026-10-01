package struct BrandConfigurationDependencies: Sendable {
    package let endpointProvider: any APIEndpointProviding
    package let responseDecoder: any BrandConfigurationResponseDecoding

    package init(
        endpointProvider: any APIEndpointProviding,
        responseDecoder: any BrandConfigurationResponseDecoding =
            LiveBrandConfigurationResponseDecoder()
    ) {
        self.endpointProvider = endpointProvider
        self.responseDecoder = responseDecoder
    }
}
