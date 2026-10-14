import Foundation
import Testing

@testable import BreadPartners

@Suite
struct SDKDependenciesTests {
    @Test
    func initializerPreservesDependencies() throws {
        let endpointProvider = LiveAPIEndpointProvider(environment: .stage)
        let httpClientFactory = LiveHTTPClientFactory()
        let brandConfigurationService = BrandConfigurationService(
            dependencies: BrandConfigurationDependencies(
                endpointProvider: endpointProvider
            )
        )
        let placementService = LivePlacementService()
        let analyticsFactory = LiveAnalyticsReporterFactory(
            endpointProvider: endpointProvider
        )
        let coordinator = RTPSCoordinator(
            environment: .stage,
            endpointProvider: endpointProvider,
            placementService: placementService
        )

        let dependencies = SDKDependencies(
            environment: .stage,
            httpClientFactory: httpClientFactory,
            endpointProvider: endpointProvider,
            brandConfigurationService: brandConfigurationService,
            placementService: placementService,
            analyticsFactory: analyticsFactory,
            rtpsCoordinator: coordinator
        )

        let storedHTTPClientFactory = try #require(
            dependencies.httpClientFactory as? LiveHTTPClientFactory
        )
        #expect(storedHTTPClientFactory === httpClientFactory)
        let storedAnalyticsFactory = try #require(
            dependencies.analyticsFactory as? LiveAnalyticsReporterFactory
        )
        #expect(storedAnalyticsFactory === analyticsFactory)
        #expect(dependencies.rtpsCoordinator is RTPSCoordinator)
        #expect(dependencies.placementService is LivePlacementService)
        #expect(dependencies.brandConfigurationService is BrandConfigurationService)
        #expect(dependencies.placementService is LivePlacementService)
        #expect(
            dependencies.endpointProvider.url(for: .prescreen)
                == endpointProvider.url(for: .prescreen)
        )
    }

    @Test
    func liveBuildsExpectedDependenciesForEnvironment() {
        let dependencies = SDKDependencies.live(environment: .uat)

        #expect(dependencies.environment == .uat)
        #expect(dependencies.httpClientFactory is LiveHTTPClientFactory)
        #expect(dependencies.analyticsFactory is LiveAnalyticsReporterFactory)
        #expect(dependencies.endpointProvider is LiveAPIEndpointProvider)
        #expect(dependencies.brandConfigurationService is BrandConfigurationService)
        #expect(dependencies.rtpsCoordinator is RTPSCoordinator)
        #expect(
            dependencies.endpointProvider.url(for: .prescreen)
                == URL(string: "https://acquire1uat.comenity.net/api/prescreen")
        )
    }
}
