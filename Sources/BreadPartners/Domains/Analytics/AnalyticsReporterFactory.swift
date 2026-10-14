//------------------------------------------------------------------------------
//  File:          AnalyticsReporterFactory.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Foundation
import BreadPartnersCore

protocol AnalyticsReporterFactory: Sendable {
    func makeReporter(httpClient: any HTTPClient) -> any AnalyticsReporting
}

final class LiveAnalyticsReporterFactory: AnalyticsReporterFactory {
    private let service: AnalyticsService

    init(endpointProvider: any APIEndpointProviding) {
        self.service = AnalyticsService(endpointProvider: endpointProvider)
    }

    func makeReporter(httpClient: any HTTPClient) -> any AnalyticsReporting {
        LiveAnalyticsReporter(service: service, httpClient: httpClient)
    }
}
