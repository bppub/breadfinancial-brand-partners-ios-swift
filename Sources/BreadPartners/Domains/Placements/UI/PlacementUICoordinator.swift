//------------------------------------------------------------------------------
//  File:          PlacementUICoordinator.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import BreadPartnersCore
import Foundation

@MainActor
final class PlacementUICoordinator: PlacementUICoordinating {
    private let challengeFactory: any ChallengeControllerFactory

    static var live: PlacementUICoordinator {
        PlacementUICoordinator(challengeFactory: LiveChallengeControllerFactory())
    }

    init(challengeFactory: any ChallengeControllerFactory) {
        self.challengeFactory = challengeFactory
    }

    func presentPlacement(
        _ response: PlacementsResponse,
        input: PlacementCoordinatorInput
    ) async {
        if input.openPlacementExperience {
            guard
                let htmlContent = PlacementContentResolver().overlayHTMLContent(in: response),
                let popupPlacementModel = try? await HTMLContentParser()
                    .extractPopupPlacementModel(from: htmlContent)
            else {
                return input.callback(
                    .sdkError(
                        error: NSError(
                            domain: "", code: 500,
                            userInfo: [NSLocalizedDescriptionKey: Constants.popupPlacementParsingError]
                        )
                    )
                )
            }

            await HTMLContentRenderer(
                integrationKey: input.integrationKey,
                merchantConfiguration: input.merchantConfiguration,
                placementsConfiguration: input.placementsConfiguration,
                splitTextAndAction: input.splitTextAndAction,
                forSwiftUI: input.forSwiftUI,
                logger: input.logger,
                analyticsReporter: input.analyticsReporter,
                callback: input.callback
            ).createPopupOverlay(
                popupPlacementModel: popupPlacementModel,
                overlayType: PlacementOverlayType(rawValue: popupPlacementModel.overlayType)
                    ?? .singleProductOverlay
            )
        } else {
            await HTMLContentRenderer(
                integrationKey: input.integrationKey,
                merchantConfiguration: input.merchantConfiguration,
                placementsConfiguration: input.placementsConfiguration,
                splitTextAndAction: input.splitTextAndAction,
                forSwiftUI: input.forSwiftUI,
                logger: input.logger,
                analyticsReporter: input.analyticsReporter,
                callback: input.callback
            ).handleTextPlacement(responseModel: response)
        }
    }

    func presentChallenge(
        htmlContent: String,
        originalURL: String,
        callback: @escaping @Sendable (BreadPartnerEvents) -> Void,
        logger: Logger,
        onComplete: @escaping @MainActor (String) -> Void
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
        _ error: NSError,
        callback: @escaping @Sendable (BreadPartnerEvents) -> Void
    ) {
        if error.domain == NetworkChallengeConstants.domain {
            callback(.sdkError(error: error))
        } else {
            callback(
                .sdkError(
                    error: NSError(
                        domain: "",
                        code: 500,
                        userInfo: [
                            NSLocalizedDescriptionKey: Constants.apiError(
                                message: error.localizedDescription
                            )
                        ]
                    )
                )
            )
        }
    }
}
