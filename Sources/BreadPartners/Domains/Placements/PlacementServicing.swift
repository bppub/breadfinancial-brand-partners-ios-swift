import Foundation

protocol PlacementServicing: Sendable {
    func fetch(
        request: PlacementRequest,
        from url: URL
    ) async throws -> PlacementsResponse
}
