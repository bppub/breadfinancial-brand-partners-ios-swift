import Foundation
import Testing

@testable import BreadPartners

@Suite
struct LivePlacementServiceTests {
    @Test
    func fetchPostsEncodedRequestAndDecodesResponse() async throws {
        let response = PlacementsResponse(placements: [], placementContent: nil)
        let httpClient = HTTPClientSpy(
            outcomes: [.success(try JSONEncoder().encode(response))]
        )
        let service = LivePlacementService()
        let url = try #require(URL(string: "https://placements.test/generate"))

        let result = try await service.fetch(
            request: PlacementRequest(brandId: "integration-key"),
            from: url,
            httpClient: httpClient
        )

        #expect(result.placements?.isEmpty == true)
        let requests = await httpClient.requests
        #expect(requests.count == 1)
        #expect(requests[0].url == url)
        #expect(requests[0].method == .POST)
        let body = try #require(requests[0].body)
        let request = try JSONDecoder().decode(PlacementRequest.self, from: body)
        #expect(request.brandId == "integration-key")
    }

    @Test
    func fetchPropagatesHTTPError() async throws {
        let expectedError = NSError(domain: "Placement", code: 7)
        let httpClient = HTTPClientSpy(outcomes: [.failure(expectedError)])
        let service = LivePlacementService()
        let url = try #require(URL(string: "https://placements.test/generate"))

        do {
            _ = try await service.fetch(
                request: PlacementRequest(),
                from: url,
                httpClient: httpClient
            )
            Issue.record("Expected HTTP error")
        } catch let error as NSError {
            #expect(error === expectedError)
        }
    }
}
