import Testing

@testable import BreadPartnersCore

@Suite
struct BrandConfigurationDependenciesTests {
    @Test
    func initializerKeepsEndpointProviderAndDefaultsLiveDecoder() {
        let endpointProvider = LiveAPIEndpointProvider(environment: .stage)
        let dependencies = BrandConfigurationDependencies(
            endpointProvider: endpointProvider
        )

        #expect(dependencies.endpointProvider is LiveAPIEndpointProvider)
        #expect(
            dependencies.responseDecoder is LiveBrandConfigurationResponseDecoder
        )
    }
}
