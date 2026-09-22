import Foundation

package protocol APIEndpointProviding: Sendable {
    func url(for endpoint: APIEndpoint) -> URL
}
