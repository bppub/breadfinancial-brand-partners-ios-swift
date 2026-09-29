import BreadPartnersCore

struct SDKDependencies {
    let httpClientFactory: any HTTPClientFactory
    let endpointProvider: any APIEndpointProviding

    init(
        httpClientFactory: any HTTPClientFactory,
        endpointProvider: any APIEndpointProviding,
    ) {
        self.httpClientFactory = httpClientFactory
        self.endpointProvider = endpointProvider
    }

    static func live(
        environment: BreadPartnersEnvironment
    ) -> SDKDependencies {
        return SDKDependencies(
            httpClientFactory: LiveHTTPClientFactory(),
            endpointProvider: LiveAPIEndpointProvider(environment: environment),
        )
    }
}
