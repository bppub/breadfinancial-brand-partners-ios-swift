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

    func presentPlacement(
        _ popupPlacementModel: PopupPlacementModel,
        merchantConfiguration: MerchantConfiguration,
        placementsConfiguration: PlacementConfiguration,
        integrationKey: String,
        logger: Logger,
        callback: @escaping (BreadPartnerEvents) -> Void
    )
}
