//------------------------------------------------------------------------------
//  File:          SDKDependencies.swift
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

struct SDKDependencies {
    let environment: BreadPartnersEnvironment
    let httpClientFactory: any HTTPClientFactory
    let endpointProvider: any APIEndpointProviding
    let brandConfigurationService: any BrandConfigurationServicing
    let placementCoordinator: any PlacementCoordinating
    let analyticsFactory: any AnalyticsReporterFactory
    let rtpsCoordinator: any RealTimePrescreenCoordinating

    init(
        environment: BreadPartnersEnvironment,
        httpClientFactory: any HTTPClientFactory,
        endpointProvider: any APIEndpointProviding,
        brandConfigurationService: any BrandConfigurationServicing,
        analyticsFactory: any AnalyticsReporterFactory,
        placementCoordinator: any PlacementCoordinating,
        rtpsCoordinator: any RealTimePrescreenCoordinating
    ) {
        self.environment = environment
        self.httpClientFactory = httpClientFactory
        self.endpointProvider = endpointProvider
        self.brandConfigurationService = brandConfigurationService
        self.placementCoordinator = placementCoordinator
        self.analyticsFactory = analyticsFactory
        self.rtpsCoordinator = rtpsCoordinator
    }

    static func live(
        environment: BreadPartnersEnvironment
    ) -> SDKDependencies {
        let endpointProvider = LiveAPIEndpointProvider(environment: environment)

        return SDKDependencies(
            environment: environment,
            httpClientFactory: LiveHTTPClientFactory(),
            endpointProvider: endpointProvider,
            brandConfigurationService: BrandConfigurationService(
                dependencies: BrandConfigurationDependencies(
                    endpointProvider: endpointProvider
                )
            ),
            analyticsFactory: LiveAnalyticsReporterFactory(
                endpointProvider: endpointProvider
            ),
            placementCoordinator: PlacementCoordinator(
                environment: environment,
                endpointProvider: endpointProvider
            ),
            rtpsCoordinator: RTPSCoordinator(
                environment: environment,
                endpointProvider: endpointProvider
            )
        )
    }
}
