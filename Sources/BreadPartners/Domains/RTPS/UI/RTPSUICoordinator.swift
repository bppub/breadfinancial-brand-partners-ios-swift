import Foundation
import UIKit

@MainActor
final class RTPSUICoordinator: RTPSUICoordinating {
    private let challengeFactory: any ChallengeControllerFactory
    private let popupFactory: any PopupFactory

    static var live: RTPSUICoordinator {
        RTPSUICoordinator(
            challengeFactory: LiveChallengeControllerFactory(),
            popupFactory: LivePopupFactory()
        )
    }

    init(
        challengeFactory: any ChallengeControllerFactory,
        popupFactory: any PopupFactory
    ) {
        self.challengeFactory = challengeFactory
        self.popupFactory = popupFactory
    }

    func presentChallenge(
        htmlContent: String,
        originalURL: String,
        callback: @escaping (BreadPartnerEvents) -> Void,
        logger: Logger,
        onComplete: @escaping (String) -> Void
    ) {
        let controller = challengeFactory.makeChallengeController(
            htmlContent: htmlContent,
            originalURL: originalURL,
            callback: callback,
            onComplete: onComplete,
            logger: logger
        )
        callback(.renderPopupView(view: controller))
    }

    func presentFailure(
        _ failure: RTPSServiceFailure,
        callback: @escaping (BreadPartnerEvents) -> Void
    ) {
        switch failure {
        case .missingRequiredFields:
            callback(
                .sdkError(
                    error: NSError(
                        domain: "",
                        code: 400,
                        userInfo: [
                            NSLocalizedDescriptionKey: Constants.prescreenRequiredFieldsError
                        ]
                    )
                )
            )
        case let .api(message):
            callback(
                .sdkError(
                    error: NSError(
                        domain: "",
                        code: 500,
                        userInfo: [
                            NSLocalizedDescriptionKey: Constants.apiError(message: message)
                        ]
                    )
                )
            )
        case let .underlying(error):
            callback(.sdkError(error: error))
        }
    }

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
    ) async {
        do {
            guard !(response.placements?.isEmpty ?? true) else {
                return callback(popupParsingError)
            }

            guard
                let content = response.placementContent?.first(where: {
                    $0.metadata?.templateId?.contains("overlay") == true
                }),
                var popupPlacementModel = try await HTMLContentParser()
                    .extractPopupPlacementModel(
                        from: content.contentData?.htmlContent ?? ""
                    )
            else {
                return callback(popupParsingError)
            }

            popupPlacementModel.overlayType = "EMBEDDED_OVERLAY"
            popupPlacementModel.location = response.placements?.first?.renderContext?.LOCATION
            popupPlacementModel.webViewUrl = response.placements?.first?.renderContext?.embeddedUrl ?? ""

            let controller = popupFactory.makePopupController(
                integrationKey: integrationKey,
                merchantConfiguration: merchantConfiguration,
                placementsConfiguration: placementsConfiguration,
                popupPlacementModel: popupPlacementModel,
                brandConfiguration: brandConfiguration,
                logger: logger,
                callback: callback
            )
            callback(.textClicked)
            callback(.renderPopupView(view: controller))
        } catch {
            callback(
                .sdkError(
                    error: NSError(
                        domain: "",
                        code: 500,
                        userInfo: [
                            NSLocalizedDescriptionKey: Constants.catchError(
                                message: error.localizedDescription
                            )
                        ]
                    )
                )
            )
        }
    }

    private var popupParsingError: BreadPartnerEvents {
        .sdkError(
            error: NSError(
                domain: "",
                code: 500,
                userInfo: [
                    NSLocalizedDescriptionKey: Constants.popupPlacementParsingError
                ]
            )
        )
    }
}
