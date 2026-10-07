//------------------------------------------------------------------------------
//  File:          BrandConfiguration.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

package struct BrandConfiguration: Equatable, Sendable {
    package let uatRecaptchaSiteKey: String
    package let stageRecaptchaSiteKey: String
    package let productionRecaptchaSiteKey: String

    package init(
        uatRecaptchaSiteKey: String,
        stageRecaptchaSiteKey: String,
        productionRecaptchaSiteKey: String
    ) {
        self.uatRecaptchaSiteKey = uatRecaptchaSiteKey
        self.stageRecaptchaSiteKey = stageRecaptchaSiteKey
        self.productionRecaptchaSiteKey = productionRecaptchaSiteKey
    }

    package func recaptchaSiteKey(for environment: BreadPartnersEnvironment) -> String {
        switch environment {
        case .uat:
            return uatRecaptchaSiteKey
        case .stage:
            return stageRecaptchaSiteKey
        case .prod:
            return productionRecaptchaSiteKey
        }
    }
}
