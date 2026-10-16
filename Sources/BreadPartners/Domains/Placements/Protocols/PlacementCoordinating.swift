//------------------------------------------------------------------------------
//  File:          PlacementCoordinating.swift
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

struct PlacementCoordinatorInput: Sendable {
    let httpClient: any HTTPClient
    let analyticsReporter: any AnalyticsReporting
    let integrationKey: String
    let merchantConfiguration: MerchantConfiguration
    let placementsConfiguration: PlacementConfiguration
    let splitTextAndAction: Bool
    let openPlacementExperience: Bool
    let forSwiftUI: Bool
    let logger: Logger
    let callback: @Sendable (BreadPartnerEvents) -> Void
}

protocol PlacementCoordinating: Sendable {
    func runFlow(_ input: PlacementCoordinatorInput) async
}
