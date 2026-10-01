import BreadPartnersCore

protocol RTPSCoordinatorFactory: Sendable {
    func makeCoordinator(httpClient: any HTTPClient) -> any RealTimePrescreenCoordinating
}

final class LiveRTPSCoordinatorFactory: RTPSCoordinatorFactory, @unchecked Sendable {
    private let environment: BreadPartnersEnvironment
    private let endpointProvider: any APIEndpointProviding

    init(
        environment: BreadPartnersEnvironment,
        endpointProvider: any APIEndpointProviding
    ) {
        self.environment = environment
        self.endpointProvider = endpointProvider
    }

    func makeCoordinator(httpClient: any HTTPClient) -> any RealTimePrescreenCoordinating {
        RTPSCoordinator(
            environment: environment,
            endpointProvider: endpointProvider,
            httpClient: httpClient
        )
    }
}
