import Foundation
import Testing

@testable import BreadPartners

@Suite
struct SDKDependenciesTests {
    @Test
    func initializerPreservesDependencies() throws {
        let endpointProvider = LiveAPIEndpointProvider(environment: .stage)
        let httpClientFactory = LiveHTTPClientFactory()
        let coordinatorFactory = LiveRTPSCoordinatorFactory(
            environment: .stage,
            endpointProvider: endpointProvider
        )

        let dependencies = SDKDependencies(
            httpClientFactory: httpClientFactory,
            endpointProvider: endpointProvider,
            rtpsCoordinatorFactory: coordinatorFactory
        )

        let storedHTTPClientFactory = try #require(
            dependencies.httpClientFactory as? LiveHTTPClientFactory
        )
        let storedCoordinatorFactory = try #require(
            dependencies.rtpsCoordinatorFactory as? LiveRTPSCoordinatorFactory
        )

        #expect(storedHTTPClientFactory === httpClientFactory)
        #expect(storedCoordinatorFactory === coordinatorFactory)
        #expect(
            dependencies.endpointProvider.url(for: .prescreen)
                == endpointProvider.url(for: .prescreen)
        )
    }

    @Test
    func liveBuildsExpectedDependenciesForEnvironment() {
        let dependencies = SDKDependencies.live(environment: .uat)

        #expect(dependencies.httpClientFactory is LiveHTTPClientFactory)
        #expect(dependencies.endpointProvider is LiveAPIEndpointProvider)
        #expect(dependencies.rtpsCoordinatorFactory is LiveRTPSCoordinatorFactory)
        #expect(
            dependencies.endpointProvider.url(for: .prescreen)
                == URL(string: "https://acquire1uat.comenity.net/api/prescreen")
        )
    }
}
