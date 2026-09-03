//------------------------------------------------------------------------------
//  File:          BrandConfigResponse.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartnersSDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

import Foundation

/// Represents the response from the brand config API.
internal struct BrandConfigResponse: Codable {
    let config: Config
}

/// Contains the brand's configuration details.
internal struct Config: Codable {
    let AEMContent: String
    let OVERRIDE_KEY: String
    let clientName: String
    let prodAdServerUrl: String
    let qaAdServerUrl: String
    let recaptchaEnabledQA: String
    let recaptchaSiteKeyQA: String
    let recaptchaSiteKeyPROD: String
    let recaptchaEnabledPROD: String
    let rskUatNativeIos: String
    let rskUatNativeAndroid: String
    let rskStageNativeIos: String
    let rskStageNativeAndroid: String
    let rskProdNativeIos: String
    let rskProdNativeAndroid: String
    let test: String

    enum CodingKeys: String, CodingKey {
        case AEMContent
        case OVERRIDE_KEY
        case clientName
        case prodAdServerUrl
        case qaAdServerUrl
        case recaptchaEnabledQA
        case recaptchaSiteKeyQA
        case recaptchaSiteKeyPROD
        case recaptchaEnabledPROD
        case rskUatNativeIos = "rsk_UAT_NATIVE_IOS"
        case rskUatNativeAndroid = "rsk_UAT_NATIVE_ANDROID"
        case rskStageNativeIos = "rsk_STAGE_NATIVE_IOS"
        case rskStageNativeAndroid = "rsk_STAGE_NATIVE_ANDROID"
        case rskProdNativeIos = "rsk_PROD_NATIVE_IOS"
        case rskProdNativeAndroid = "rsk_PROD_NATIVE_ANDROID"
        case test
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.AEMContent =
            try container.decodeIfPresent(String.self, forKey: .AEMContent)
            ?? ""
        self.OVERRIDE_KEY =
            try container.decodeIfPresent(String.self, forKey: .OVERRIDE_KEY)
            ?? ""
        self.clientName =
            try container.decodeIfPresent(String.self, forKey: .clientName)
            ?? ""
        self.prodAdServerUrl =
            try container.decodeIfPresent(String.self, forKey: .prodAdServerUrl)
            ?? ""
        self.qaAdServerUrl =
            try container.decodeIfPresent(String.self, forKey: .qaAdServerUrl)
            ?? ""
        self.recaptchaEnabledQA =
            try container.decodeIfPresent(
                String.self, forKey: .recaptchaEnabledQA) ?? ""
        self.recaptchaSiteKeyQA =
            try container.decodeIfPresent(
                String.self, forKey: .recaptchaSiteKeyQA) ?? ""
        self.recaptchaSiteKeyPROD =
            try container.decodeIfPresent(
                String.self, forKey: .recaptchaSiteKeyPROD) ?? ""
        self.recaptchaEnabledPROD =
            try container.decodeIfPresent(
                String.self, forKey: .recaptchaEnabledPROD) ?? ""
        self.rskUatNativeIos =
            try container.decodeIfPresent(
                String.self, forKey: .rskUatNativeIos) ?? ""
        self.rskUatNativeAndroid =
            try container.decodeIfPresent(
                String.self, forKey: .rskUatNativeAndroid) ?? ""
        self.rskStageNativeIos =
            try container.decodeIfPresent(
                String.self, forKey: .rskStageNativeIos) ?? ""
        self.rskStageNativeAndroid =
            try container.decodeIfPresent(
                String.self, forKey: .rskStageNativeAndroid) ?? ""
        self.rskProdNativeIos =
            try container.decodeIfPresent(
                String.self, forKey: .rskProdNativeIos) ?? ""
        self.rskProdNativeAndroid =
            try container.decodeIfPresent(
                String.self, forKey: .rskProdNativeAndroid) ?? ""
        self.test =
            try container.decodeIfPresent(String.self, forKey: .test) ?? ""
    }
}

extension Config {
    func getRecaptchaKey(for environment: BreadPartnersEnvironment) -> String {
        switch environment {
        case .uat:
            return rskUatNativeIos
        case .stage:
            return rskStageNativeIos
        case .prod:
            return rskProdNativeIos
        }
    }
}
