//------------------------------------------------------------------------------
//  File:          BrandConfigurationTests.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Testing

@testable import BreadPartnersCore

@Suite
struct BrandConfigurationTests {
    private let configuration = BrandConfiguration(
        uatRecaptchaSiteKey: "uat-key",
        stageRecaptchaSiteKey: "stage-key",
        productionRecaptchaSiteKey: "production-key"
    )

    @Test(arguments: [
        (BreadPartnersEnvironment.uat, "uat-key"),
        (BreadPartnersEnvironment.stage, "stage-key"),
        (BreadPartnersEnvironment.prod, "production-key"),
    ])
    func recaptchaSiteKeyMatchesEnvironment(
        environment: BreadPartnersEnvironment,
        expectedKey: String
    ) {
        #expect(configuration.recaptchaSiteKey(for: environment) == expectedKey)
    }
}
