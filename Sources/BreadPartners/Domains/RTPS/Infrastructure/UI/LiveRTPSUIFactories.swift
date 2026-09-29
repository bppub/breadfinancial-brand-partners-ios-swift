import Foundation
import UIKit

@MainActor
struct LiveChallengeControllerFactory: ChallengeControllerFactory {
    func makeChallengeController(
        htmlContent: String,
        originalURL: String,
        callback: @escaping (BreadPartnerEvents) -> Void,
        onComplete: @escaping (String) -> Void,
        logger: Logger
    ) -> UIViewController {
        ChallengeController(
            htmlContent: htmlContent,
            originalURL: originalURL,
            callback: callback,
            onComplete: onComplete,
            logger: logger
        )
    }
}

@MainActor
struct LivePopupFactory: PopupFactory {
    func makePopupController(
        integrationKey: String,
        merchantConfiguration: MerchantConfiguration,
        placementsConfiguration: PlacementConfiguration,
        popupPlacementModel: PopupPlacementModel,
        brandConfiguration: BrandConfigResponse?,
        logger: Logger,
        callback: @escaping (BreadPartnerEvents) -> Void
    ) -> UIViewController {
        PopupController(
            integrationKey: integrationKey,
            merchantConfiguration: merchantConfiguration,
            placementConfiguration: placementsConfiguration,
            popupModel: popupPlacementModel,
            overlayType: .embeddedOverlay,
            brandConfiguration: brandConfiguration,
            logger: logger,
            callback: callback
        )
    }
}
