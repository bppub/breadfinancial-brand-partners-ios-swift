//------------------------------------------------------------------------------
//  File:          PlacementPopupPresenter.swift
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

@MainActor
final class PlacementPopupPresenter {
    private let logger: Logger
    private let analyticsReporter: any AnalyticsReporting
    private let placementsConfiguration: PlacementConfiguration
    private let callback: (BreadPartnerEvents) -> Void
    private let onLoadFollowUpPopupModel: @MainActor @Sendable (String?) async throws -> PopupPlacementModel?
    private let popupPlacementModelParser: @MainActor (String) async throws -> PopupPlacementModel?
    private let overlayTypeResolver: @MainActor (String) async -> PlacementOverlayType?

    init(
        logger: Logger,
        analyticsReporter: any AnalyticsReporting,
        placementsConfiguration: PlacementConfiguration,
        callback: @escaping (BreadPartnerEvents) -> Void,
        onLoadFollowUpPopupModel: @escaping @MainActor @Sendable (String?) async throws -> PopupPlacementModel?,
        popupPlacementModelParser: @escaping @MainActor (String) async throws -> PopupPlacementModel? = {
            htmlContent in
            try await HTMLContentParser().extractPopupPlacementModel(from: htmlContent)
        },
        overlayTypeResolver: @escaping @MainActor (String) async -> PlacementOverlayType? = { overlayType in
            await HTMLContentParser().handleOverlayType(from: overlayType)
        }
    ) {
        self.logger = logger
        self.analyticsReporter = analyticsReporter
        self.placementsConfiguration = placementsConfiguration
        self.callback = callback
        self.onLoadFollowUpPopupModel = onLoadFollowUpPopupModel
        self.popupPlacementModelParser = popupPlacementModelParser
        self.overlayTypeResolver = overlayTypeResolver
    }

    func presentActionPopup(
        responseModel: PlacementsResponse,
        textPlacementModel: TextPlacementModel
    ) async {
        guard
            let popupPlacementHTMLContent = responseModel.placementContent?
                .first(where: { $0.id == textPlacementModel.actionContentId }),
            let popupPlacementModel = try? await popupPlacementModelParser(
                popupPlacementHTMLContent.contentData?.htmlContent ?? ""
            )
        else {
            callback(
                .sdkError(
                    error: NSError(
                        domain: "", code: 500,
                        userInfo: [NSLocalizedDescriptionKey: Constants.popupPlacementParsingError]
                    )
                )
            )
            return
        }

        logger.logPopupPlacementModelDetails(popupPlacementModel)

        guard let overlayType = await overlayTypeResolver(popupPlacementModel.overlayType) else {
            callback(
                .sdkError(
                    error: NSError(
                        domain: "", code: 500,
                        userInfo: [NSLocalizedDescriptionKey: Constants.missingPopupPlacementError]
                    )
                )
            )
            return
        }

        Task {
            await analyticsReporter.send(
                event: .clickPlacement,
                placementResponse: responseModel
            )
        }

        presentPopup(popupPlacementModel: popupPlacementModel, overlayType: overlayType)
    }

    func presentPopup(popupPlacementModel: PopupPlacementModel, overlayType: PlacementOverlayType) {
        let popupViewController = PopupController(
            input: PlacementPopupInputMapper().map(
                popupPlacementModel,
                overlayType: overlayType,
                style: placementsConfiguration.popUpStyling,
                loadFollowUp: onLoadFollowUpPopupModel
            ),
            logger: logger,
            callback: callback
        )

        callback(.textClicked)
        popupViewController.modalPresentationStyle = .overCurrentContext
        popupViewController.modalTransitionStyle = .crossDissolve
        popupViewController.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        callback(.renderPopupView(view: popupViewController))
    }
}
