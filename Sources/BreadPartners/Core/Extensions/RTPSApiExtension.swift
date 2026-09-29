//------------------------------------------------------------------------------
//  File:          RTPSApiExtension.swift
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

extension BreadPartnersSDK {
    /// Makes RTPS (Real-Time Pre-Screen) API calls with conditional reCaptcha token validation.
    ///
    /// This method handles three different flows:
    /// 1. **Batch Prescreen Flow**: When `customerAcceptedOffer` is true, skips RTPS and directly fetches placement data.
    /// 2. **Prescreen Flow**: When `prescreenId` is nil, calls the prescreen endpoint with a reCaptcha token for bot protection.
    /// 3. **Virtual Lookup Flow**: When `prescreenId` is known, calls the virtualLookup endpoint without a reCaptcha token.
    ///
    /// - Parameters:
    ///   - merchantConfiguration: Merchant and buyer configuration details.
    ///   - placementsConfiguration: Placement configuration including RTPS data.
    ///   - splitTextAndAction: Whether to split text and action components.
    ///   - openPlacementExperience: Whether to automatically open the placement experience.
    ///   - forSwiftUI: Whether the view is for SwiftUI.
    ///   - logger: Logger instance for tracking events.
    ///   - callback: Callback to handle SDK events.
    internal func rtpsCall(
        merchantConfiguration: MerchantConfiguration,
        placementsConfiguration: PlacementConfiguration,
        splitTextAndAction: Bool = false,
        openPlacementExperience: Bool = false,
        forSwiftUI: Bool = false,
        logger: Logger,
        cookies: String? = nil,
        callback:
            @Sendable @escaping (
                BreadPartnerEvents
            ) -> Void
    ) async {
        let siteKey = brandConfiguration?.config.getRecaptchaKey(
            for: merchantConfiguration.env ?? BreadPartnersEnvironment.prod
        )

        let outcome = await RTPSService(dependencies: rtpsDependencies).execute(
            RTPSServiceInput(
                merchantConfiguration: merchantConfiguration,
                rtpsData: placementsConfiguration.rtpsData ?? RTPSData(),
                integrationKey: integrationKey,
                siteKey: siteKey ?? "",
                prescreenURL: dependencies.endpointProvider.url(for: .prescreen),
                virtualLookupURL: dependencies.endpointProvider.url(for: .virtualLookup),
                cookies: cookies,
                isLoggingEnabled: logger.isLoggingEnabled,
                log: { logger.printLog($0) }
            ))

        switch outcome {
        case .noAction:
            return

        case .skipToPlacements:
            return await fetchRTPSData(
                merchantConfiguration: merchantConfiguration,
                placementsConfiguration: placementsConfiguration,
                splitTextAndAction: splitTextAndAction,
                openPlacementExperience: openPlacementExperience,
                forSwiftUI: forSwiftUI,
                logger: logger,
                callback: callback)

        case let .proceedToPlacements(response):
            placementsConfiguration.rtpsData?.prescreenId = response.prescreenId
            placementsConfiguration.rtpsData?.cardType = response.cardType
            await fetchRTPSData(
                merchantConfiguration: response.updateMerchantConfiguration(merchantConfiguration),
                placementsConfiguration: placementsConfiguration,
                splitTextAndAction: splitTextAndAction,
                openPlacementExperience: openPlacementExperience,
                forSwiftUI: forSwiftUI,
                logger: logger,
                callback: callback)

        case let .challenge(htmlContent, url):
            let challengeController = ChallengeController(
                htmlContent: htmlContent,
                originalURL: url,
                callback: callback,
                onComplete: { cookie in
                    Task {
                        await self.rtpsCall(
                            merchantConfiguration: merchantConfiguration,
                            placementsConfiguration: placementsConfiguration,
                            splitTextAndAction: splitTextAndAction,
                            openPlacementExperience: openPlacementExperience,
                            forSwiftUI: forSwiftUI,
                            logger: logger,
                            cookies: cookie,
                            callback: callback
                        )
                    }
                },
                logger: logger
            )

            return callback(.renderPopupView(view: challengeController))

        case .failure(.missingRequiredFields):
            callback(
                .sdkError(
                    error: NSError(
                        domain: "", code: 400,
                        userInfo: [
                            NSLocalizedDescriptionKey: Constants.prescreenRequiredFieldsError
                        ]
                    )
                )
            )

        case let .failure(.api(message)):
            callback(
                .sdkError(
                    error: NSError(
                        domain: "", code: 500,
                        userInfo: [
                            NSLocalizedDescriptionKey: Constants.apiError(message: message)
                        ]
                    )
                )
            )

        case let .failure(.underlying(error)):
            callback(.sdkError(error: error))
        }
    }

    /// This method is called to fetch placement data,
    /// which will be displayed as a text view with a clickable button in the brand partner's UI.
    func fetchRTPSData(
        merchantConfiguration: MerchantConfiguration,
        placementsConfiguration: PlacementConfiguration,
        splitTextAndAction: Bool = false,
        openPlacementExperience: Bool = false,
        forSwiftUI: Bool = false,
        logger: Logger,
        callback:
            @Sendable @escaping (
                BreadPartnerEvents
            ) -> Void
    ) async {
        do {
            let url = dependencies.endpointProvider.url(for: .generatePlacements)

            let webURL: URL?
            if placementsConfiguration.rtpsData?.customerAcceptedOffer == true {
                webURL =
                    WebURLBuilder.buildBPSWebURL(
                        environment: sdkEnvironment,
                        integrationKey: integrationKey,
                        rtpsData: placementsConfiguration.rtpsData,
                        placementData: placementsConfiguration.placementData,
                        merchantConfiguration: merchantConfiguration
                    )
            } else {
                webURL =
                    WebURLBuilder.buildRTPSWebURL(
                        environment: sdkEnvironment,
                        integrationKey: integrationKey,
                        rtpsData: placementsConfiguration.rtpsData,
                        merchantConfiguration: merchantConfiguration,
                    )
            }

            let request = PlacementRequest(
                placements: [
                    PlacementRequestBody(
                        context: ContextRequestBody(
                            ENV: merchantConfiguration.env?.rawValue,
                            LOCATION: "RTPS-Approval",
                            embeddedUrl: webURL?.absoluteString
                        )
                    )
                ], brandId: integrationKey
            )

            let response = try await rtpsDependencies.httpClient.request(
                HTTPRequest(
                    url: url,
                    method: .POST,
                    body: try JSONEncoder().encode(request)
                )
            )
            await handleRTPSPlacementResponse(
                merchantConfiguration: merchantConfiguration,
                placementsConfiguration: placementsConfiguration,
                splitTextAndAction: false, openPlacementExperience: true,
                forSwiftUI: false,
                logger: logger,
                callback: callback,
                response)
        } catch {
            return callback(
                .sdkError(
                    error: NSError(
                        domain: "", code: 500,
                        userInfo: [
                            NSLocalizedDescriptionKey: Constants.apiError(
                                message: error.localizedDescription)
                        ])))
        }
    }

    func handleRTPSPlacementResponse(
        merchantConfiguration: MerchantConfiguration,
        placementsConfiguration: PlacementConfiguration,
        splitTextAndAction: Bool = false,
        openPlacementExperience: Bool = false,
        forSwiftUI: Bool = false,
        logger: Logger,
        callback:
            @Sendable @escaping (
                BreadPartnerEvents
            ) -> Void,
        _ response: Data
    ) async {
        do {
            let responseModel: PlacementsResponse = try rtpsDependencies.responseDecoder.decode(
                PlacementsResponse.self,
                from: response
            )
            if responseModel.placements?.isEmpty ?? true {
                return callback(
                    .sdkError(
                        error: NSError(
                            domain: "", code: 500,
                            userInfo: [
                                NSLocalizedDescriptionKey: Constants
                                    .popupPlacementParsingError
                            ])))
            }

            guard
                let popupPlacementHTMLContent = responseModel
                    .placementContent?
                    .first(where: { $0.metadata?.templateId?.contains("overlay") == true }),
                var popupPlacementModel = try await HTMLContentParser()
                    .extractPopupPlacementModel(
                        from: popupPlacementHTMLContent.contentData?
                            .htmlContent
                            ?? ""
                    )
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

            popupPlacementModel.overlayType = "EMBEDDED_OVERLAY"
            popupPlacementModel.location = responseModel.placements?.first?.renderContext?.LOCATION
            popupPlacementModel.webViewUrl = responseModel.placements?.first?.renderContext?.embeddedUrl ?? ""
            await HTMLContentRenderer(
                integrationKey: integrationKey,
                merchantConfiguration: merchantConfiguration,
                placementsConfiguration: placementsConfiguration,
                brandConfiguration: brandConfiguration,
                splitTextAndAction: splitTextAndAction,
                forSwiftUI: forSwiftUI,
                logger: logger,
                callback: callback
            ).createPopupOverlay(
                popupPlacementModel: popupPlacementModel,
                overlayType: .embeddedOverlay
            )

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
}
