//------------------------------------------------------------------------------
//  File:          HTMLContentRenderer.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

import Foundation
import UIKit

/// Renders parsed HTML content into native UI elements.
@MainActor
internal class HTMLContentRenderer {

    var integrationKey: String = ""
    var merchantConfiguration: MerchantConfiguration?
    var placementsConfiguration: PlacementConfiguration?

    let brandConfiguration: BrandConfigResponse?
    var splitTextAndAction: Bool = false
    var forSwiftUI: Bool = false

    var logger: Logger = Logger()
    let callback: ((BreadPartnerEvents) -> Void)

    init(
        integrationKey: String,
        merchantConfiguration: MerchantConfiguration?,
        placementsConfiguration: PlacementConfiguration?,
        brandConfiguration: BrandConfigResponse?,
        splitTextAndAction: Bool = false,
        forSwiftUI: Bool = false,
        logger: Logger,
        callback: @escaping ((BreadPartnerEvents) -> Void)
    ) {
        self.integrationKey = integrationKey
        self.merchantConfiguration = merchantConfiguration
        self.placementsConfiguration = placementsConfiguration
        self.brandConfiguration = brandConfiguration
        self.splitTextAndAction = splitTextAndAction
        self.forSwiftUI = forSwiftUI
        self.logger = logger
        self.callback = callback
    }

    var textPlacementModel: TextPlacementModel? = nil
    var responseModel: PlacementsResponse? = nil

    func handleTextPlacement(responseModel: PlacementsResponse) async {
        self.responseModel = responseModel

        do {
            guard
                let placementContent = responseModel.placementContent?.first?
                    .contentData?.htmlContent
            else {
                return callback(
                    .sdkError(
                        error: NSError(
                            domain: "", code: 500,
                            userInfo: [
                                NSLocalizedDescriptionKey: Constants
                                    .noTextPlacementError
                            ])))
            }

            guard
                let parseTextPlacementModel =
                    try await HTMLContentParser().extractTextPlacementModel(
                        htmlContent: placementContent)
            else {
                return callback(
                    .sdkError(
                        error: NSError(
                            domain: "", code: 500,
                            userInfo: [
                                NSLocalizedDescriptionKey: Constants
                                    .textPlacementParsingError
                            ])))
            }

            textPlacementModel = parseTextPlacementModel
            guard let textPlacementModel = textPlacementModel else { return }

            logger.logTextPlacementModelDetails(textPlacementModel)
            Task {
                await AnalyticsManager(logger: logger).sendViewPlacement(
                    placementResponse: responseModel)
            }

            if self.splitTextAndAction {
                renderTextAndButton()
            } else {
                renderTextViewWithLink()
            }
        } catch {

            return callback(
                .sdkError(
                    error: NSError(
                        domain: "", code: 500,
                        userInfo: [
                            NSLocalizedDescriptionKey: Constants.catchError(
                                message: error.localizedDescription)
                        ])))
        }
    }

    func handlePopupPlacement(
        responseModel: PlacementsResponse,
        textPlacementModel: TextPlacementModel
    ) async {
        guard
            let popupPlacementHTMLContent = responseModel.placementContent?
                .first(where: {
                    $0.id == textPlacementModel.actionContentId
                }),
            let popupPlacementModel =
                try? await HTMLContentParser().extractPopupPlacementModel(
                    from: popupPlacementHTMLContent.contentData?.htmlContent
                        ?? "")
        else {

            return callback(
                .sdkError(
                    error: NSError(
                        domain: "", code: 500,
                        userInfo: [
                            NSLocalizedDescriptionKey: Constants
                                .popupPlacementParsingError
                        ])))
        }

        logger.logPopupPlacementModelDetails(popupPlacementModel)

        guard
            let overlayType = await HTMLContentParser().handleOverlayType(
                from: popupPlacementModel.overlayType)
        else {

            return callback(
                .sdkError(
                    error: NSError(
                        domain: "", code: 500,
                        userInfo: [
                            NSLocalizedDescriptionKey: Constants
                                .missingPopupPlacementError
                        ])))
        }

        Task {
            await AnalyticsManager(logger: logger).sendClickPlacement(
                placementResponse: responseModel)
        }
        await createPopupOverlay(
            popupPlacementModel: popupPlacementModel, overlayType: overlayType)
    }

    func createPopupOverlay(
        popupPlacementModel: PopupPlacementModel,
        overlayType: PlacementOverlayType
    ) async {
        let popupViewController = PopupController(
            integrationKey: integrationKey,
            merchantConfiguration: merchantConfiguration!,
            placementConfiguration: placementsConfiguration!,
            popupModel: popupPlacementModel,
            overlayType: overlayType,
            brandConfiguration: brandConfiguration,
            logger: logger,
            callback: callback
        )
        configurePopupPresentation(popupViewController)
    }

    private func configurePopupPresentation(
        _ popupViewController: PopupController
    ) {
        callback(.textClicked)
        popupViewController.modalPresentationStyle = .overCurrentContext
        popupViewController.modalTransitionStyle = .crossDissolve
        popupViewController.view.backgroundColor = UIColor.black
            .withAlphaComponent(0.5)
        callback(.renderPopupView(view: popupViewController))
    }
}
