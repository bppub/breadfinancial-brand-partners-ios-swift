import Foundation

package enum HTTPMethod: String, Sendable {
    case GET
    case POST
    case PUT
    case DELETE
    case OPTIONS
}

package struct HTTPRequest: Sendable {
    package let url: URL
    package let method: HTTPMethod
    package let headers: [String: String]
    package let cookies: String?
    package let body: Data?

    package init(
        url: URL,
        method: HTTPMethod,
        headers: [String: String] = [:],
        cookies: String? = nil,
        body: Data? = nil
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.cookies = cookies
        self.body = body
    }
}

package protocol HTTPClient: Sendable {
    func request(_ request: HTTPRequest) async throws -> Data
}
