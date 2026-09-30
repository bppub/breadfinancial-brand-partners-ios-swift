import Foundation
import Testing

@testable import BreadPartners

@Suite
struct HTTPClientSpyTests {
    @Test
    func returnsQueuedDataAndRecordsEachRequest() async throws {
        let firstData = Data("first".utf8)
        let secondData = Data("second".utf8)
        let httpClient = HTTPClientSpy(
            outcomes: [.success(firstData), .success(secondData)]
        )
        let firstRequest = HTTPRequest(
            url: try #require(URL(string: "https://api.test/first")),
            method: .POST
        )
        let secondRequest = HTTPRequest(
            url: try #require(URL(string: "https://api.test/second")),
            method: .POST
        )

        #expect(try await httpClient.request(firstRequest) == firstData)
        #expect(try await httpClient.request(secondRequest) == secondData)
        #expect(await httpClient.requestCount == 2)
        #expect(await httpClient.requests.map(\.url) == [firstRequest.url, secondRequest.url])
    }

    @Test
    func throwsConfiguredFailureAfterRecordingRequest() async throws {
        let httpClient = HTTPClientSpy(
            outcomes: [.failure(NSError(domain: "Network", code: 500))]
        )
        let request = HTTPRequest(
            url: try #require(URL(string: "https://api.test/failure")),
            method: .POST
        )

        do {
            _ = try await httpClient.request(request)
            Issue.record("Expected the configured network failure")
        } catch {
            #expect((error as NSError).domain == "Network")
            #expect((error as NSError).code == 500)
        }

        #expect(await httpClient.requestCount == 1)
    }

    @Test
    func returnsEmptyDataWhenQueueIsExhausted() async throws {
        let httpClient = HTTPClientSpy(outcomes: [])
        let request = HTTPRequest(
            url: try #require(URL(string: "https://api.test/empty")),
            method: .POST
        )

        #expect(try await httpClient.request(request) == Data())
        #expect(await httpClient.requestCount == 1)
    }
}
