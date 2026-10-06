import BreadPartnersCore
import Foundation

struct LivePlacementService: PlacementServicing {
    func fetch(
        request: PlacementRequest,
        from url: URL,
        httpClient: any HTTPClient
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
