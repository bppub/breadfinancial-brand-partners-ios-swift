import Foundation
import Testing

@testable import BreadPartners

struct BrandConfigurationServiceFactoryTests {
    @Test
    func liveFactoryMakesBrandConfigurationService() {
        let factory = LiveBrandConfigurationServiceFactory(
            endpointProvider: LiveAPIEndpointProvider(environment: .stage)
        )

        let service = factory.makeService(httpClient: HTTPClientSpy(outcomes: []))

        #expect(service is LiveBrandConfigurationService)
    }

    @Test
    func liveFactoryForwardsHTTPClientAndEndpointProvider() async throws {
        let httpClient = HTTPClientSpy(
            outcomes: [.success(Data(#"{"config":{}}"#.utf8))]
        )
        let endpointProvider = LiveAPIEndpointProvider(environment: .uat)
        let factory = LiveBrandConfigurationServiceFactory(
            endpointProvider: endpointProvider
        )
        let service = factory.makeService(httpClient: httpClient)

        _ = try #require(await service.fetch(brandID: "brand-key"))

        let request = try #require(await httpClient.requests.first)
        #expect(
            request.url
                == endpointProvider.url(for: .brandConfig(brandId: "brand-key"))
        )
    }
}
