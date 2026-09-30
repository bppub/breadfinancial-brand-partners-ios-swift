import BreadPartnersCore
import Foundation

struct LivePlacementService: PlacementServicing {
    private let httpClient: any HTTPClient

    init(httpClient: any HTTPClient) {
        self.httpClient = httpClient
    }

    func fetch(
        request: PlacementRequest,
        from url: URL
    ) async throws -> PlacementsResponse {
        let data = try await httpClient.request(
            HTTPRequest(
                url: url,
                method: .POST,
                body: try JSONEncoder().encode(request)
            )
        )

        return try JSONDecoder().decode(PlacementsResponse.self, from: data)
    }
}
