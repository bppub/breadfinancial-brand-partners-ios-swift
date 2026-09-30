import Foundation
import UIKit

@MainActor
protocol ChallengeControllerFactory: Sendable {
    func makeChallengeController(
        htmlContent: String,
        originalURL: String,
        callback: @escaping (BreadPartnerEvents) -> Void,
        onComplete: @escaping (String) -> Void,
        logger: Logger
    ) -> UIViewController
}

@MainActor
protocol PopupFactory: Sendable {
    func makePopupController(
        integrationKey: String,
        merchantConfiguration: MerchantConfiguration,
        placementsConfiguration: PlacementConfiguration,
        popupPlacementModel: PopupPlacementModel,
        logger: Logger,
        callback: @escaping (BreadPartnerEvents) -> Void
    ) -> UIViewController
}
