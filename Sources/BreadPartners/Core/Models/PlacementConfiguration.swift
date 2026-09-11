//------------------------------------------------------------------------------
//  File:          PlacementConfiguration.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

/// Structure that used to provide configurations for  `registerPlacement` or `submitRTPS` methods.
/// - Parameters:
///   - placementData: Defines text placements on the brand partner screen for the `registerPlacementFlow`.
///   - rtpsData: Specifies the real-time pre-screen configuration for the prescreen flow.
///   - popUpStyling: Configures the popup styling for each element rendered within the popup.
public struct PlacementConfiguration: @unchecked Sendable {
    package let data: PlacementConfigurationData

    public var placementData: PlacementData? { data.placementData }
    public var rtpsData: RTPSData? { data.rtpsData }
    public var popUpStyling: PopUpStyling?

    public init(
        placementData: PlacementData? = nil,
        rtpsData: RTPSData? = nil,
        popUpStyling: PopUpStyling? = nil
    ) {
        self.data = PlacementConfigurationData(
            placementData: placementData,
            rtpsData: rtpsData
        )
        self.popUpStyling = popUpStyling
    }
}
