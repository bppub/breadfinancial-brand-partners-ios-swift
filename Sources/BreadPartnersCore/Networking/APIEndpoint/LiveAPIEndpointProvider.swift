import Foundation

package struct LiveAPIEndpointProvider: APIEndpointProviding {
    private let environment: BreadPartnersEnvironment

    package init(environment: BreadPartnersEnvironment) {
        self.environment = environment
    }

    package func url(for endpoint: APIEndpoint) -> URL {
        let urlString = endpoint.url(for: environment)

        guard let url = URL(string: urlString) else {
            preconditionFailure("APIEndpoint produced an invalid URL: \(urlString)")
        }

        return url
    }
}
