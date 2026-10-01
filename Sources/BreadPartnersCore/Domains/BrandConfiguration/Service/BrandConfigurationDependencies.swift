import BreadPartnersCore

struct BrandConfigurationDependencies: Sendable {
    let httpClient: any HTTPClient
    let endpointProvider: any APIEndpointProviding
    let responseDecoder: any BrandConfigurationResponseDecoding

    init(
        httpClient: any HTTPClient,
        endpointProvider: any APIEndpointProviding,
        responseDecoder: any BrandConfigurationResponseDecoding
    ) {
        self.httpClient = httpClient
        self.endpointProvider = endpointProvider
        self.responseDecoder = responseDecoder
    }
}
