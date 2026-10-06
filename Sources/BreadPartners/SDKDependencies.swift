import BreadPartnersCore

struct SDKDependencies {
    let httpClientFactory: any HTTPClientFactory
    let endpointProvider: any APIEndpointProviding
    let brandConfigurationService: any BrandConfigurationServicing
    let placementService: any PlacementServicing
    let rtpsCoordinator: any RealTimePrescreenCoordinating

    init(
        httpClientFactory: any HTTPClientFactory,
        endpointProvider: any APIEndpointProviding,
        brandConfigurationService: any BrandConfigurationServicing,
        placementService: any PlacementServicing,
        rtpsCoordinator: any RealTimePrescreenCoordinating
    ) {
        self.httpClientFactory = httpClientFactory
        self.endpointProvider = endpointProvider
        self.brandConfigurationService = brandConfigurationService
        self.placementService = placementService
        self.rtpsCoordinator = rtpsCoordinator
    }

    static func live(
        environment: BreadPartnersEnvironment
    ) -> SDKDependencies {
        let endpointProvider = LiveAPIEndpointProvider(environment: environment)
        let placementService = LivePlacementService()

        return SDKDependencies(
            httpClientFactory: LiveHTTPClientFactory(),
            endpointProvider: endpointProvider,
            brandConfigurationService: BrandConfigurationService(
                dependencies: BrandConfigurationDependencies(
                    endpointProvider: endpointProvider
                )
            ),
            placementService: placementService,
            rtpsCoordinator: RTPSCoordinator(
                environment: environment,
                endpointProvider: endpointProvider,
                placementService: placementService
            )
        )
    }
}
