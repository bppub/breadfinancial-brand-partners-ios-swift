//------------------------------------------------------------------------------
//  File:          PlacementUICoordinating.swift
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
protocol PlacementUICoordinating: Sendable {
    func presentPlacement(
        _ response: PlacementsResponse,
        input: PlacementCoordinatorInput,
        onFetchFollowUpPlacement: @escaping @MainActor @Sendable (String?) async throws -> PlacementsResponse
    ) async
    func presentChallenge(
        htmlContent: String,
        originalURL: String,
        callback: @escaping @Sendable (BreadPartnerEvents) -> Void,
        logger: Logger,
        onComplete: @escaping @MainActor (String) -> Void
    )
    func presentFailure(
        _ error: NSError,
        callback: @escaping @Sendable (BreadPartnerEvents) -> Void
    )
}
