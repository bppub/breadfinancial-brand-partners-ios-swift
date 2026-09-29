import BreadPartnersCore

struct SDKDependencies {
    let logger: Logger
    let httpClientFactory: any HTTPClientFactory
    let endpointProvider: any APIEndpointProviding

    init(
        logger: Logger,
        httpClientFactory: any HTTPClientFactory,
        endpointProvider: any APIEndpointProviding,
    ) {
        self.logger = logger
        self.httpClientFactory = httpClientFactory
        self.endpointProvider = endpointProvider
    }

    static func live(
        environment: BreadPartnersEnvironment,
        logger: Logger
    ) -> SDKDependencies {
        return SDKDependencies(
            logger: logger,
            httpClientFactory: LiveHTTPClientFactory(),
            endpointProvider: LiveAPIEndpointProvider(environment: environment),
        )
    }
}
