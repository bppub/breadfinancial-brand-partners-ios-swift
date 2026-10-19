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
    private let followUpPopupModelParser: @Sendable (String) async throws -> PopupPlacementModel?

    static var live: PlacementUICoordinator {
        PlacementUICoordinator(challengeFactory: LiveChallengeControllerFactory())
    }

    init(
        challengeFactory: any ChallengeControllerFactory,
        followUpPopupModelParser: @escaping @Sendable (String) async throws -> PopupPlacementModel? = {
            htmlContent in
            try await HTMLContentParser().extractPopupPlacementModel(from: htmlContent)
        }
    ) {
        self.challengeFactory = challengeFactory
        self.followUpPopupModelParser = followUpPopupModelParser
    }

    func presentPlacement(
        _ response: PlacementsResponse,
        input: PlacementCoordinatorInput,
        onFetchFollowUpPlacement: @escaping @MainActor @Sendable (String?) async throws -> PlacementsResponse
    ) async {
        let renderer = HTMLContentRenderer(
            integrationKey: input.integrationKey,
            merchantConfiguration: input.merchantConfiguration,
            placementsConfiguration: input.placementsConfiguration,
            splitTextAndAction: input.splitTextAndAction,
            forSwiftUI: input.forSwiftUI,
            logger: input.logger,
            analyticsReporter: input.analyticsReporter,
            callback: input.callback,
            onLoadFollowUpPopupModel: makeFollowUpPopupModelLoader(
                onFetchFollowUpPlacement: onFetchFollowUpPlacement,
                callback: input.callback
            )
        )

        if input.openPlacementExperience {
            guard
                let htmlContent = try? PlacementContentResolver()
                    .firstOverlayTemplate(in: response)
                    .contentData?.htmlContent,
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

            await renderer.createPopupOverlay(
                popupPlacementModel: popupPlacementModel,
                overlayType: PlacementOverlayType(rawValue: popupPlacementModel.overlayType)
                    ?? .singleProductOverlay
            )
        } else {
            await renderer.handleTextPlacement(responseModel: response)
        }
    }

    private func makeFollowUpPopupModelLoader(
        onFetchFollowUpPlacement: @escaping @MainActor @Sendable (String?) async throws -> PlacementsResponse,
        callback: @escaping @Sendable (BreadPartnerEvents) -> Void
    ) -> @MainActor @Sendable (String?) async throws -> PopupPlacementModel? {
        return { placementID in
            let response = try await onFetchFollowUpPlacement(placementID)
            do {
                guard
                    let followUpContent = try? PlacementContentResolver()
                        .firstPopupFollowUpContent(in: response),
                    let popupPlacementModel = try await self.followUpPopupModelParser(
                        followUpContent.contentData?.htmlContent ?? ""
                    )
                else {
                    callback(
                        .sdkError(
                            error: NSError(
                                domain: "",
                                code: 500,
                                userInfo: [
                                    NSLocalizedDescriptionKey: Constants.popupPlacementParsingError
                                ]
                            )
                        )
                    )
                    return nil
                }

                return popupPlacementModel
            } catch {
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
                return nil
            }
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
