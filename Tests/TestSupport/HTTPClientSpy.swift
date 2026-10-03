import BreadPartnersCore
import Foundation

package actor HTTPClientSpy: HTTPClient {
    package enum Outcome: Sendable {
        case success(Data)
        case failure(NSError)
    }

    package enum Failure: LocalizedError, Equatable {
        case unexpectedRequest(method: HTTPMethod, url: URL)

        package var errorDescription: String? {
            switch self {
            case let .unexpectedRequest(method, url):
                return
                    "HTTPClientSpy received an unexpected \(method.rawValue) request to \(url.absoluteString): no outcomes remain."
            }
        }
    }

    private var outcomes: [Outcome]
    package private(set) var requests: [HTTPRequest] = []

    package var requestCount: Int {
        requests.count
    }

    package init(outcomes: [Outcome]) {
        self.outcomes = outcomes
    }

    package func request(_ request: HTTPRequest) async throws -> Data {
        requests.append(request)
        guard !outcomes.isEmpty else {
            throw Failure.unexpectedRequest(method: request.method, url: request.url)
        }

        switch outcomes.removeFirst() {
        case let .success(data):
            return data
        case let .failure(error):
            throw error
        }
    }
}
