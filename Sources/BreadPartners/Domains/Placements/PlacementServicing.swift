import Foundation

protocol PlacementServicing: Sendable {
    func fetch(
        request: PlacementRequest,
        from url: URL,
        httpClient: any HTTPClient
    ) async throws -> PlacementsResponse
}
