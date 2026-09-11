//------------------------------------------------------------------------------
//  File:          BreadPartnersSDK.swift
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

/// The primary interface class for interacting with the Bread Partners SDK.
/// Provides entry points for initialization, configuration, and SDK-level actions.
public class BreadPartnersSDK: NSObject, UITextViewDelegate {

    public static var shared: BreadPartnersSDK = {
        let instance = BreadPartnersSDK()
        return instance
    }()

    var integrationKey: String = ""
    var isLoggingEnabled: Bool = false

    var sdkEnvironment: BreadPartnersEnvironment = .stage
    var brandConfiguration: BrandConfigResponse?
    private var isInitialized: Bool = false

    private func checkInitialized(
        callback: @Sendable @escaping (BreadPartnerEvents) -> Void
    ) -> Bool {
        guard isInitialized else {
            let error = NSError(
                domain: "BreadPartnersSDK",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "SDK not initialized. Call setup() first."]
            )
            callback(.sdkError(error: error))
            return false
        }
        return true
    }

    /// Call this function when the app launches.
    /// - Parameters:
    ///   - integrationKey: A unique key specific to the brand.
    ///   - enableLog: Set this to `true` if you want to see debug logs.
    ///   - environment: Specifies the SDK environment, such as production (.prod) or development (stage).
    public func setup(
        environment: BreadPartnersEnvironment = .prod,
        integrationKey: String,
        enableLog: Bool
    ) async {
        await APIUrl.setEnvironment(environment)
        self.sdkEnvironment = environment
        self.integrationKey = integrationKey
        self.isLoggingEnabled = enableLog
        let logger = Logger()
        logger.setLogging(enabled: isLoggingEnabled)
        isInitialized = true
        return await fetchBrandConfig(logger: logger)
    }

    /// Use this function to display text placements in your app's UI.
    /// - Parameters:
    ///   - merchantConfiguration: Provide user account details in this configuration.
    ///   - placementsConfiguration: Specify the pre-defined placement details required for building the UI.
    ///   - splitTextAndAction: Set this to `true` if you want the placement to return either text with a link or a combination of text and button.
    ///   - forSwiftUI: A Boolean flag indicating whether the text view should be created as a SwiftUI-compatible view.
    ///   - callback: A function that handles user interactions and ongoing events related to the placements.
    public func registerPlacements(
        merchantConfiguration: MerchantConfiguration,
        placementsConfiguration: PlacementConfiguration,
        splitTextAndAction: Bool = false,
        forSwiftUI: Bool = false,
        callback:
            @Sendable @escaping (
                BreadPartnerEvents
            ) -> Void
    ) async {
        guard checkInitialized(callback: callback) else { return }
        var mutablePlacementsConfiguration = placementsConfiguration

        if mutablePlacementsConfiguration.popUpStyling == nil {
            mutablePlacementsConfiguration.popUpStyling = BreadPartnerDefaults.popupStyle
        }

        let logger = Logger()
        logger.setLogging(enabled: isLoggingEnabled)
        logger.setCallback(callback)

        await fetchPlacementData(
            merchantConfiguration: merchantConfiguration,
            placementsConfiguration: mutablePlacementsConfiguration,
            splitTextAndAction: splitTextAndAction,
            openPlacementExperience: false,
            forSwiftUI: forSwiftUI,
            logger: logger,
            callback: callback
        )
    }

    /// Calls this function to check if the user qualifies for a pre-screen card application.
    /// This call will be completely silent with no impact on user behavior.
    /// Everything will be managed within the SDK, and the brand partner's application only needs to send metadata.
    /// If any step fails within the RTPS flow, the user will not experience any UI behavior changes.
    /// If RTPS succeeds, a popup should be displayed via the callback to show the "Approved" flow.
    ///
    /// - Parameters:
    ///   - merchantConfiguration: Provide user account details in this configuration.
    ///   - placementsConfiguration: Specify the pre-defined placement details required for building the UI.
    ///   - splitTextAndAction: Set this to `true` if you want the placement to return either text with a link or a combination of text and button.
    ///   - forSwiftUI: A Boolean flag indicating whether the text view should be created as a SwiftUI-compatible view.
    ///   - callback: A function that handles user interactions and ongoing events related to the placements.
    public func silentRTPSRequest(
        merchantConfiguration: MerchantConfiguration,
        placementsConfiguration: PlacementConfiguration,
        splitTextAndAction: Bool = false,
        forSwiftUI: Bool = false,
        callback:
            @Sendable @escaping (
                BreadPartnerEvents
            ) -> Void
    ) async {
        guard checkInitialized(callback: callback) else { return }
        var mutablePlacementsConfiguration = placementsConfiguration

        if mutablePlacementsConfiguration.popUpStyling == nil {
            mutablePlacementsConfiguration.popUpStyling = BreadPartnerDefaults.popupStyle
        }

        let logger = Logger()
        logger.setLogging(enabled: isLoggingEnabled)
        logger.setCallback(callback)

        // This will fetch reCaptcha keys if it was not done yet.
        if (brandConfiguration == nil) {
            await fetchBrandConfig(logger: logger)
        }

        await rtpsCall(
            merchantConfiguration: merchantConfiguration,
            placementsConfiguration: mutablePlacementsConfiguration,
            splitTextAndAction: splitTextAndAction,
            openPlacementExperience: false,
            forSwiftUI: forSwiftUI,
            logger: logger,
            callback: callback
        )
    }

    /// Display an overlay to the customer without requiring them to click on a placement to trigger it.
    /// - Parameters:
    ///   - merchantConfiguration: Provide user account details in this configuration.
    ///   - placementsConfiguration: Specify the pre-defined placement details required for building the UI.
    ///   - forSwiftUI: A Boolean flag indicating whether the text view should be created as a SwiftUI-compatible view.
    ///   - callback: A function that handles user interactions and ongoing events related to the placements.
    public func openExperienceForPlacement(
        merchantConfiguration: MerchantConfiguration,
        placementsConfiguration: PlacementConfiguration,
        forSwiftUI: Bool = false,
        callback:
            @Sendable @escaping (
                BreadPartnerEvents
            ) -> Void
    ) async {
        guard checkInitialized(callback: callback) else { return }
        var mutablePlacementsConfiguration = placementsConfiguration

        if mutablePlacementsConfiguration.popUpStyling == nil {
            mutablePlacementsConfiguration.popUpStyling = BreadPartnerDefaults.popupStyle
        }

        let logger = Logger()
        logger.setLogging(enabled: isLoggingEnabled)
        logger.setCallback(callback)

        await fetchPlacementData(
            merchantConfiguration: merchantConfiguration,
            placementsConfiguration: mutablePlacementsConfiguration,
            splitTextAndAction: false, openPlacementExperience: true,
            forSwiftUI: false,
            logger: logger,
            callback: callback
        )
    }
}
