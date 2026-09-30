import BreadPartnersCore
import Foundation

actor HTTPClientSpy: HTTPClient {
    enum Outcome: Sendable {
        case success(Data)
        case failure(NSError)
    }

    private var outcomes: [Outcome]
    private(set) var requests: [HTTPRequest] = []

    var requestCount: Int {
        requests.count
    }

    init(outcomes: [Outcome]) {
        self.outcomes = outcomes
    }

    func request(_ request: HTTPRequest) async throws -> Data {
        requests.append(request)
        let outcome = outcomes.isEmpty ? .success(Data()) : outcomes.removeFirst()

        switch outcome {
        case let .success(data):
            return data
        case let .failure(error):
            throw error
        }
    }
}
