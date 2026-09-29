import Foundation

protocol HTTPClientFactory: Sendable {
    func makeClient(logger: Logger) -> any HTTPClient
}

final class LiveHTTPClientFactory: HTTPClientFactory, @unchecked Sendable {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func makeClient(logger: Logger) -> any HTTPClient {
        LiveHTTPClient(logger: logger, session: session)
    }
}
