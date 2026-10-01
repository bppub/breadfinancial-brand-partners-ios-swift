import BreadPartnersCore

struct SDKDependencies {
    let httpClientFactory: any HTTPClientFactory
    let endpointProvider: any APIEndpointProviding
    let brandConfigurationService: any BrandConfigurationServicing
    let rtpsCoordinatorFactory: any RTPSCoordinatorFactory

    init(
        httpClientFactory: any HTTPClientFactory,
        endpointProvider: any APIEndpointProviding,
        brandConfigurationService: any BrandConfigurationServicing,
        rtpsCoordinatorFactory: any RTPSCoordinatorFactory
    ) {
        self.httpClientFactory = httpClientFactory
        self.endpointProvider = endpointProvider
        self.brandConfigurationService = brandConfigurationService
        self.rtpsCoordinatorFactory = rtpsCoordinatorFactory
    }

    static func live(
        environment: BreadPartnersEnvironment
    ) -> SDKDependencies {
        let endpointProvider = LiveAPIEndpointProvider(environment: environment)

        return SDKDependencies(
            httpClientFactory: LiveHTTPClientFactory(),
            endpointProvider: endpointProvider,
            brandConfigurationService: BrandConfigurationService(
                dependencies: BrandConfigurationDependencies(
                    endpointProvider: endpointProvider
                )
            ),
            rtpsCoordinatorFactory: LiveRTPSCoordinatorFactory(
                environment: environment,
                endpointProvider: endpointProvider
            )
        )
    }
}
