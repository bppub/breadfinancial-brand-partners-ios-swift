import Foundation

package enum RTPSHTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case options = "OPTIONS"
}

package struct RTPSNetworkRequest: Sendable {
    package let url: URL
    package let method: RTPSHTTPMethod
    package let headers: [String: String]
    package let cookies: String?
    package let body: Data?

    package init(
        url: URL,
        method: RTPSHTTPMethod,
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

package struct RTPSNetworkResponse: Sendable {
    package let data: Data
    package let statusCode: Int
    package let headers: [String: String]

    package init(data: Data, statusCode: Int, headers: [String: String] = [:]) {
        self.data = data
        self.statusCode = statusCode
        self.headers = headers
    }
}

package protocol RTPSNetworkClient: Sendable {
    func send(_ request: RTPSNetworkRequest) async throws -> RTPSNetworkResponse
}
