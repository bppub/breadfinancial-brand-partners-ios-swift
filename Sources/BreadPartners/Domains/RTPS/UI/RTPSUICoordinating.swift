import Foundation

@MainActor
protocol RTPSUICoordinating: Sendable {
    func presentChallenge(
        htmlContent: String,
        originalURL: String,
        callback: @escaping (BreadPartnerEvents) -> Void,
        logger: Logger,
        onComplete: @escaping (String) -> Void
    )

    func presentFailure(
        _ failure: RTPSServiceFailure,
        callback: @escaping (BreadPartnerEvents) -> Void
    )

    func presentPlacementResponse(
        _ response: PlacementsResponse,
        merchantConfiguration: MerchantConfiguration,
        placementsConfiguration: PlacementConfiguration,
        integrationKey: String,
        brandConfiguration: BrandConfigResponse?,
        splitTextAndAction: Bool,
        openPlacementExperience: Bool,
        forSwiftUI: Bool,
        logger: Logger,
        callback: @escaping (BreadPartnerEvents) -> Void
    ) async
}
