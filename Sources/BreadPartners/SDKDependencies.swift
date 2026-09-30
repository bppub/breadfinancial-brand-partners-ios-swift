import BreadPartnersCore

struct SDKDependencies {
    let httpClientFactory: any HTTPClientFactory
    let endpointProvider: any APIEndpointProviding
    let rtpsCoordinatorFactory: any RTPSCoordinatorFactory

    init(
        httpClientFactory: any HTTPClientFactory,
        endpointProvider: any APIEndpointProviding,
        rtpsCoordinatorFactory: any RTPSCoordinatorFactory
    ) {
        self.httpClientFactory = httpClientFactory
        self.endpointProvider = endpointProvider
        self.rtpsCoordinatorFactory = rtpsCoordinatorFactory
    }

    static func live(
        environment: BreadPartnersEnvironment
    ) -> SDKDependencies {
        let endpointProvider = LiveAPIEndpointProvider(environment: environment)

        return SDKDependencies(
            httpClientFactory: LiveHTTPClientFactory(),
            endpointProvider: endpointProvider,
            rtpsCoordinatorFactory: LiveRTPSCoordinatorFactory(
                environment: environment,
                endpointProvider: endpointProvider
            )
        )
    }
}
