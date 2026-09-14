import BreadPartnersCore
import Foundation

package struct LiveRTPSNetworkClient: RTPSNetworkClient {
    private let logger: Logger

    init(logger: Logger) {
        self.logger = logger
    }

    package func send(_ request: RTPSNetworkRequest) async throws -> RTPSNetworkResponse {
        let response = try await APIClient(logger: logger).request(
            urlString: request.url.absoluteString,
            method: HTTPMethod(rawValue: request.method.rawValue) ?? .POST,
            headers: request.headers,
            cookies: request.cookies,
            body: request.body
        )

        let data: Data
        if let responseData = response.value as? Data {
            data = responseData
        } else if let dictionary = response.value as? [String: Any] {
            data = try JSONSerialization.data(withJSONObject: dictionary)
        } else {
            throw NSError(
                domain: "BreadPartners",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Invalid RTPS response format"]
            )
        }

        return RTPSNetworkResponse(data: data, statusCode: 200)
    }
}
