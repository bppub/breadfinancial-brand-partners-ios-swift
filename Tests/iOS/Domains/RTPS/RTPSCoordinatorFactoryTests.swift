import Testing

@testable import BreadPartners

struct RTPSCoordinatorFactoryTests {
    @Test
    func liveFactoryMakesRTPSCoordinator() {
        let factory = LiveRTPSCoordinatorFactory(
            environment: .stage,
            endpointProvider: LiveAPIEndpointProvider(environment: .stage)
        )

        let coordinator = factory.makeCoordinator(httpClient: HTTPClientSpy(outcomes: []))

        #expect(coordinator is RTPSCoordinator)
    }
}
