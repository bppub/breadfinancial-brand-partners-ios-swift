//------------------------------------------------------------------------------
//  File:          RealTimePrescreenCoordinating.swift
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

struct RealTimePrescreenInput: @unchecked Sendable {
    let httpClient: any HTTPClient
    let merchantConfiguration: MerchantConfiguration
    let placementsConfiguration: PlacementConfiguration
    let integrationKey: String
    let brandConfiguration: BrandConfiguration?
    let splitTextAndAction: Bool
    let openPlacementExperience: Bool
    let forSwiftUI: Bool
    let logger: Logger
    let callback: @Sendable (BreadPartnerEvents) -> Void

    func withResponseUpdates(_ response: RTPSResponse) -> Self {
        var updatedPlacementsConfiguration = placementsConfiguration
        updatedPlacementsConfiguration.rtpsData?.prescreenId = response.prescreenId
        updatedPlacementsConfiguration.rtpsData?.cardType = response.cardType

        return Self(
            httpClient: httpClient,
            merchantConfiguration: response.updateMerchantConfiguration(
                merchantConfiguration
            ),
            placementsConfiguration: updatedPlacementsConfiguration,
            integrationKey: integrationKey,
            brandConfiguration: brandConfiguration,
            splitTextAndAction: splitTextAndAction,
            openPlacementExperience: openPlacementExperience,
            forSwiftUI: forSwiftUI,
            logger: logger,
            callback: callback
        )
    }
}

protocol RealTimePrescreenCoordinating: Sendable {
    func runFlow(_ input: RealTimePrescreenInput) async
}
