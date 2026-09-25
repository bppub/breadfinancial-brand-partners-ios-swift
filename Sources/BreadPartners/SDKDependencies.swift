import BreadPartnersCore

struct SDKDependencies {
    var endpointProvider: any APIEndpointProviding

    static func live(environment: BreadPartnersEnvironment = .prod) -> SDKDependencies {
        SDKDependencies(
            endpointProvider: LiveAPIEndpointProvider(environment: environment)
        )
    }
}
