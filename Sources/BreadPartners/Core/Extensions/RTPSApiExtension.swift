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
import RecaptchaEnterprise

extension BreadPartnersSDK {
    /// This method does bot behavior check using the Recaptcha v3 SDK,
    /// to protect against malicious attacks.
    private func executeSecurityCheck(
        merchantConfiguration: MerchantConfiguration,
        logger: Logger
    ) async throws -> String {
        let siteKey = brandConfiguration?.config.getRecaptchaKey(
            for: merchantConfiguration.env ?? BreadPartnersEnvironment.prod
        )

        let token = try await RecaptchaManager.shared.executeReCaptcha(
            siteKey: siteKey ?? "",
            action: .init(customAction: "checkout"),
            timeout: 10000,
            debug: logger.isLoggingEnabled
        )

        return token
    }

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
        do {
            // Check for Batch Prescreen Flow when prescreen id has to be entered by user.
            if (placementsConfiguration.rtpsData?.customerAcceptedOffer == true) {
                return await fetchRTPSData(
                    merchantConfiguration: merchantConfiguration,
                    placementsConfiguration: placementsConfiguration,
                    splitTextAndAction: splitTextAndAction,
                    openPlacementExperience: openPlacementExperience,
                    forSwiftUI: forSwiftUI,
                    logger: logger,
                    callback: callback)
            }

            // Check if it is a regular RTPS flow or Batch Prescreen (prescreenId is known).
            let isPrescreen = placementsConfiguration.rtpsData?.prescreenId == nil

            // Validate required fields for prescreen requests
            if isPrescreen {
                let buyer = merchantConfiguration.buyer
                let billingAddress = buyer?.billingAddress

                // Check if firstname, lastname, and complete address are provided
                guard let givenName = buyer?.givenName, !givenName.isEmpty,
                    let familyName = buyer?.familyName, !familyName.isEmpty,
                    let address1 = billingAddress?.address1, !address1.isEmpty,
                    let country = billingAddress?.country, !country.isEmpty,
                    let locality = billingAddress?.locality, !locality.isEmpty,
                    let region = billingAddress?.region, !region.isEmpty,
                    let postalCode = billingAddress?.postalCode, !postalCode.isEmpty
                else {
                    logger.printLog("Buyer information is missing or wrong.")
                    return callback(
                        .sdkError(
                            error: NSError(
                                domain: "", code: 400,
                                userInfo: [
                                    NSLocalizedDescriptionKey: Constants.prescreenRequiredFieldsError
                                ]
                            )
                        )
                    )
                }
            }

            // Only obtain reCaptcha token for prescreen requests
            let reCaptchaToken: String?
            if isPrescreen {
                reCaptchaToken = try await executeSecurityCheck(
                    merchantConfiguration: merchantConfiguration,
                    logger: logger
                )
            } else {
                reCaptchaToken = nil
                logger.printLog("Skipping reCaptcha token generation for virtual lookup call.")
            }

            let apiUrl = APIUrl(
                urlType: isPrescreen ? .prescreen : .virtualLookup
            ).url

            let requestBuilder = RTPSRequestBuilder(
                merchantConfiguration: merchantConfiguration,
                rtpsData: placementsConfiguration.rtpsData!,
                reCaptchaToken: reCaptchaToken
            )

            let headers: [String: String] = [
                Constants.headerClientKey: integrationKey,
                Constants.headerRequestedWithKey: Constants
                    .headerRequestedWithValue,
            ]

            if (cookies != nil) {
                logger.printLog("Attaching cookies to RTPS request: \(cookies!)")
            } else {
                logger.printLog("No Cookies")
            }

            let rtpsRequestBuilt = requestBuilder.build()

            let response = try await APIClient(logger: logger).request(
                urlString: apiUrl,
                method: .POST,
                headers: headers,
                cookies: cookies,
                body: rtpsRequestBuilt
            )

            let preScreenLookupResponse: RTPSResponse = try ResponseDecoder.decode(
                response,
                as: RTPSResponse.self
            )
            let returnResultType = preScreenLookupResponse.returnCode
            let prescreenResult = getPrescreenResult(
                from: returnResultType ?? "10")
            logger.printLog("PreScreenID:Result: \(prescreenResult )")

            // Since this call runs in the background without user interaction,
            // if the result is not "approved"(in case of regular prescreen call) and not "account found" (in case of lookup call)
            // or prescreenId is nill (in case user is approved, but already has an account),
            // we simply return without taking any further action.
            if (prescreenResult != .approved && prescreenResult != .accountFound)
                || preScreenLookupResponse.prescreenId == nil
            {
                return
            }

            // Map response data back to configurations.
            placementsConfiguration.rtpsData!.prescreenId =
                preScreenLookupResponse.prescreenId
            placementsConfiguration.rtpsData?.cardType = preScreenLookupResponse.cardType

            await fetchRTPSData(
                merchantConfiguration: preScreenLookupResponse.updateMerchantConfiguration(merchantConfiguration),
                placementsConfiguration: placementsConfiguration,
                splitTextAndAction: splitTextAndAction,
                openPlacementExperience: openPlacementExperience,
                forSwiftUI: forSwiftUI,
                logger: logger,
                callback: callback)

        } catch let error as NSError {
            if error.domain == Constants.incapsulaChallenge {
                guard let htmlContent = error.userInfo[Constants.htmlContent] as? String,
                    let url = error.userInfo[Constants.url] as? String
                else {
                    return callback(.sdkError(error: error))
                }

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
            } else {
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
            let apiUrl = APIUrl(urlType: .generatePlacements).url

            let webURL: String?
            if placementsConfiguration.rtpsData?.customerAcceptedOffer == true {
                webURL =
                    WebURLBuilder.buildBPSWebURL(
                        integrationKey: integrationKey,
                        merchantConfiguration: merchantConfiguration,
                        placementConfiguration: placementsConfiguration
                    )?.absoluteString
            } else {
                webURL =
                    WebURLBuilder.buildRTPSWebURL(
                        integrationKey: integrationKey,
                        merchantConfiguration: merchantConfiguration,
                        rtpsData: placementsConfiguration.rtpsData!,
                        prescreenId: placementsConfiguration.rtpsData!.prescreenId
                    )?.absoluteString
            }

            let request = PlacementRequest(
                placements: [
                    PlacementRequestBody(
                        context: ContextRequestBody(
                            ENV: merchantConfiguration.env?.rawValue,
                            LOCATION: "RTPS-Approval",
                            embeddedUrl: webURL
                        )
                    )
                ], brandId: integrationKey
            )

            let response = try await APIClient(logger: logger).request(
                urlString: apiUrl, method: .POST, body: request
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
        _ response: AnySendable
    ) async {
        do {
            let responseModel: PlacementsResponse = try ResponseDecoder.decode(
                response,
                as: PlacementsResponse.self
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
