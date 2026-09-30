@testable import BreadPartners

@MainActor
final class RTPSUICoordinatorSpy: RTPSUICoordinating, @unchecked Sendable {
    private(set) var challengeCallCount = 0
    private(set) var failureCallCount = 0
    private(set) var placementCallCount = 0
    private(set) var lastFailure: RTPSServiceFailure?
    private(set) var challengeHTMLContent: String?
    private(set) var challengeOriginalURL: String?
    private(set) var popupPlacementModel: PopupPlacementModel?
    private var challengeCompletion: ((String) -> Void)?

    func presentChallenge(
        htmlContent: String,
        originalURL: String,
        callback: @escaping (BreadPartnerEvents) -> Void,
        logger: Logger,
        onComplete: @escaping (String) -> Void
    ) {
        challengeCallCount += 1
        challengeHTMLContent = htmlContent
        challengeOriginalURL = originalURL
        challengeCompletion = onComplete
    }

    func completeChallenge(with cookie: String) {
        challengeCompletion?(cookie)
    }

    func presentFailure(
        _ failure: RTPSServiceFailure,
        callback: @escaping (BreadPartnerEvents) -> Void
    ) {
        failureCallCount += 1
        lastFailure = failure
    }

    func presentPlacement(
        _ popupPlacementModel: PopupPlacementModel,
        merchantConfiguration: MerchantConfiguration,
        placementsConfiguration: PlacementConfiguration,
        integrationKey: String,
        brandConfiguration: BrandConfigResponse?,
        logger: Logger,
        callback: @escaping (BreadPartnerEvents) -> Void
    ) {
        placementCallCount += 1
        self.popupPlacementModel = popupPlacementModel
    }
}
