//------------------------------------------------------------------------------
//  File:          RTPSUICoordinator.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

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

    func presentPlacement(
        _ popupPlacementModel: PopupPlacementModel,
        merchantConfiguration: MerchantConfiguration,
        placementsConfiguration: PlacementConfiguration,
        integrationKey: String,
        logger: Logger,
        callback: @escaping (BreadPartnerEvents) -> Void
    ) {
        let controller = popupFactory.makePopupController(
            integrationKey: integrationKey,
            merchantConfiguration: merchantConfiguration,
            placementsConfiguration: placementsConfiguration,
            popupPlacementModel: popupPlacementModel,
            overlayType: .embeddedOverlay,
            logger: logger,
            callback: callback
        )
        callback(.textClicked)
        callback(.renderPopupView(view: controller))
    }
}
