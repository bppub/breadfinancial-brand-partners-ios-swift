import Foundation
@testable import BreadPartners

final class HTTPDataLoadingSpy: HTTPDataLoading, @unchecked Sendable {
    var responseData: Data
    let response: URLResponse
    private(set) var request: URLRequest?

    init(responseData: Data, response: URLResponse) {
        self.responseData = responseData
        self.response = response
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        self.request = request
        return (responseData, response)
    }
}
