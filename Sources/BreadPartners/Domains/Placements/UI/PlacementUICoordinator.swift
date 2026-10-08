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
import UIKit

enum PlacementTextRenderMode: Sendable, Equatable {
    case linkedText
    case splitTextAndAction
    case swiftUILinkedText
    case swiftUISplitTextAndAction
}

@MainActor
protocol PlacementTextRendering {
    func renderTextPlacement(
        responseModel: PlacementsResponse,
        mode: PlacementTextRenderMode
    ) async throws
}

@MainActor
final class PlacementUICoordinator {
    private let textRenderer: any PlacementTextRendering
    private let challengeFactory: any ChallengeControllerFactory
    private let popupFactory: any PopupFactory

    init(
        textRenderer: any PlacementTextRendering,
        challengeFactory: any ChallengeControllerFactory,
        popupFactory: any PopupFactory
    ) {
        self.textRenderer = textRenderer
        self.challengeFactory = challengeFactory
        self.popupFactory = popupFactory
    }

    func handle(
        _ outcome: PlacementOutcome,
        renderMode: PlacementTextRenderMode,
        logger: Logger,
        callback: @escaping (BreadPartnerEvents) -> Void,
        onChallengeComplete: @escaping (String) -> Void
    ) async {
        switch outcome {
        case let .success(responseModel):
            do {
                try await textRenderer.renderTextPlacement(
                    responseModel: responseModel,
                    mode: renderMode
                )
            } catch {
                presentFailure(error, callback: callback)
            }

        case let .challenge(htmlContent, originalURL, _):
            presentChallenge(
                htmlContent: htmlContent,
                originalURL: originalURL,
                logger: logger,
                callback: callback,
                onComplete: onChallengeComplete
            )

        case let .failure(error):
            presentFailure(error, callback: callback)
        }
    }

    func presentPopup(
        _ popupPlacementModel: PopupPlacementModel,
        overlayType: PlacementOverlayType,
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
            overlayType: overlayType,
            logger: logger,
            callback: callback
        )
        controller.modalPresentationStyle = .overCurrentContext
        controller.modalTransitionStyle = .crossDissolve
        controller.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        callback(.textClicked)
        callback(.renderPopupView(view: controller))
    }

    private func presentChallenge(
        htmlContent: String,
        originalURL: String,
        logger: Logger,
        callback: @escaping (BreadPartnerEvents) -> Void,
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

    private func presentFailure(
        _ error: Error,
        callback: @escaping (BreadPartnerEvents) -> Void
    ) {
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

extension HTMLContentRenderer: PlacementTextRendering {
    func renderTextPlacement(
        responseModel: PlacementsResponse,
        mode: PlacementTextRenderMode
    ) async throws {
        splitTextAndAction = mode == .splitTextAndAction || mode == .swiftUISplitTextAndAction
        forSwiftUI = mode == .swiftUILinkedText || mode == .swiftUISplitTextAndAction
        await handleTextPlacement(responseModel: responseModel)
    }
}
