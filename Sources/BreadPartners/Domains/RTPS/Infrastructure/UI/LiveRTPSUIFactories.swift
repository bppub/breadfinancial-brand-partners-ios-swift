//------------------------------------------------------------------------------
//  File:          LiveRTPSUIFactories.swift
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
        overlayType: PlacementOverlayType,
        logger: Logger,
        callback: @escaping (BreadPartnerEvents) -> Void
    ) -> UIViewController {
        PopupController(
            integrationKey: integrationKey,
            merchantConfiguration: merchantConfiguration,
            placementConfiguration: placementsConfiguration,
            popupModel: popupPlacementModel,
            overlayType: overlayType,
            logger: logger,
            callback: callback
        )
    }
}
