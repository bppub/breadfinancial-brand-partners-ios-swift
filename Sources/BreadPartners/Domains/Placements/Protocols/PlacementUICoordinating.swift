import BreadPartnersCore
import Foundation

@MainActor
protocol PlacementUICoordinating: Sendable {
    func presentPlacement(
        _ response: PlacementsResponse,
        input: PlacementCoordinatorInput
    ) async
    func presentChallenge(
        htmlContent: String,
        originalURL: String,
        callback: @escaping @Sendable (BreadPartnerEvents) -> Void,
        logger: Logger,
        onComplete: @escaping @MainActor (String) -> Void
    )
    func presentFailure(
        _ error: NSError,
        callback: @escaping @Sendable (BreadPartnerEvents) -> Void
    )
}