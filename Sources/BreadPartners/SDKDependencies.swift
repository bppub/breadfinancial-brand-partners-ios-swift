import BreadPartnersCore

struct SDKDependencies {
    let logger: Logger
    let httpClient: any HTTPClient
    let endpointProvider: any APIEndpointProviding

    init(
        logger: Logger,
        httpClient: any HTTPClient,
        endpointProvider: any APIEndpointProviding,
    ) {
        self.logger = logger
        self.httpClient = httpClient
        self.endpointProvider = endpointProvider
    }

    static func live(
        environment: BreadPartnersEnvironment,
        logger: Logger
    ) -> SDKDependencies {
        return SDKDependencies(
            logger: logger,
            httpClient: LiveHTTPClient(logger: logger),
            endpointProvider: LiveAPIEndpointProvider(environment: environment),
        )
    }
}
