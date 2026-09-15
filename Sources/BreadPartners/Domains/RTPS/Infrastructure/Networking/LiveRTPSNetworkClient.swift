import BreadPartnersCore
import Foundation

package struct LiveRTPSNetworkClient: RTPSNetworkClient {
    private let logger: Logger

    init(logger: Logger) {
        self.logger = logger
    }

    package func send(_ request: RTPSNetworkRequest) async throws -> Data {
        return try await APIClient(logger: logger).requestData(
            urlString: request.url.absoluteString,
            method: request.method,
            headers: request.headers,
            cookies: request.cookies,
            body: request.body
        )
    }
}
