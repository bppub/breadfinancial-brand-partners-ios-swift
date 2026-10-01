import Testing

@testable import BreadPartnersCore

@Suite
struct BrandConfigurationDependenciesTests {
    @Test
    func initializerPreservesDependencies() {
        let httpClient = HTTPClientSpy()
        let endpointProvider = LiveAPIEndpointProvider(environment: .stage)
        let responseDecoder = LiveBrandConfigurationResponseDecoder()

        let dependencies = BrandConfigurationDependencies(
            httpClient: httpClient,
            endpointProvider: endpointProvider,
            responseDecoder: responseDecoder
        )

        #expect(dependencies.httpClient is HTTPClientSpy)
        #expect(dependencies.endpointProvider is LiveAPIEndpointProvider)
        #expect(
            dependencies.responseDecoder is LiveBrandConfigurationResponseDecoder
        )
    }

    @Test
    func initializerDefaultsToLiveResponseDecoder() {
        let dependencies = BrandConfigurationDependencies(
            httpClient: HTTPClientSpy(),
            endpointProvider: LiveAPIEndpointProvider(environment: .stage)
        )

        #expect(
            dependencies.responseDecoder is LiveBrandConfigurationResponseDecoder
        )
    }
}
