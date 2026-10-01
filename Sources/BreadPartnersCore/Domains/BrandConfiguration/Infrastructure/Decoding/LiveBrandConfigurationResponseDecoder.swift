import Foundation

struct LiveBrandConfigurationResponseDecoder: BrandConfigurationResponseDecoding {
    func decode(from data: Data) throws -> BrandConfiguration {
        let response = try JSONDecoder().decode(
            BrandConfigurationResponse.self,
            from: data
        )

        return BrandConfiguration(
            uatRecaptchaSiteKey: response.config.uatRecaptchaSiteKey,
            stageRecaptchaSiteKey: response.config.stageRecaptchaSiteKey,
            productionRecaptchaSiteKey: response.config.productionRecaptchaSiteKey
        )
    }
}

private struct BrandConfigurationResponse: Decodable {
    let config: BrandConfigurationPayload
}

private struct BrandConfigurationPayload: Decodable {
    let aemContent: String
    let overrideKey: String
    let clientName: String
    let prodAdServerUrl: String
    let qaAdServerUrl: String
    let recaptchaEnabledQA: String
    let recaptchaSiteKeyQA: String
    let recaptchaSiteKeyPROD: String
    let recaptchaEnabledPROD: String
    let uatRecaptchaSiteKey: String
    let uatRecaptchaSiteKeyAndroid: String
    let stageRecaptchaSiteKey: String
    let stageRecaptchaSiteKeyAndroid: String
    let productionRecaptchaSiteKey: String
    let productionRecaptchaSiteKeyAndroid: String
    let test: String

    private enum CodingKeys: String, CodingKey {
        case aemContent = "AEMContent"
        case overrideKey = "OVERRIDE_KEY"
        case clientName
        case prodAdServerUrl
        case qaAdServerUrl
        case recaptchaEnabledQA
        case recaptchaSiteKeyQA
        case recaptchaSiteKeyPROD
        case recaptchaEnabledPROD
        case uatRecaptchaSiteKey = "rsk_UAT_NATIVE_IOS"
        case uatRecaptchaSiteKeyAndroid = "rsk_UAT_NATIVE_ANDROID"
        case stageRecaptchaSiteKey = "rsk_STAGE_NATIVE_IOS"
        case stageRecaptchaSiteKeyAndroid = "rsk_STAGE_NATIVE_ANDROID"
        case productionRecaptchaSiteKey = "rsk_PROD_NATIVE_IOS"
        case productionRecaptchaSiteKeyAndroid = "rsk_PROD_NATIVE_ANDROID"
        case test
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        aemContent = try Self.decodeString(from: container, forKey: .aemContent)
        overrideKey = try Self.decodeString(from: container, forKey: .overrideKey)
        clientName = try Self.decodeString(from: container, forKey: .clientName)
        prodAdServerUrl = try Self.decodeString(from: container, forKey: .prodAdServerUrl)
        qaAdServerUrl = try Self.decodeString(from: container, forKey: .qaAdServerUrl)
        recaptchaEnabledQA = try Self.decodeString(from: container, forKey: .recaptchaEnabledQA)
        recaptchaSiteKeyQA = try Self.decodeString(from: container, forKey: .recaptchaSiteKeyQA)
        recaptchaSiteKeyPROD = try Self.decodeString(from: container, forKey: .recaptchaSiteKeyPROD)
        recaptchaEnabledPROD = try Self.decodeString(from: container, forKey: .recaptchaEnabledPROD)
        uatRecaptchaSiteKey = try Self.decodeString(from: container, forKey: .uatRecaptchaSiteKey)
        uatRecaptchaSiteKeyAndroid = try Self.decodeString(from: container, forKey: .uatRecaptchaSiteKeyAndroid)
        stageRecaptchaSiteKey = try Self.decodeString(from: container, forKey: .stageRecaptchaSiteKey)
        stageRecaptchaSiteKeyAndroid = try Self.decodeString(from: container, forKey: .stageRecaptchaSiteKeyAndroid)
        productionRecaptchaSiteKey = try Self.decodeString(from: container, forKey: .productionRecaptchaSiteKey)
        productionRecaptchaSiteKeyAndroid = try Self.decodeString(
            from: container, forKey: .productionRecaptchaSiteKeyAndroid)
        test = try Self.decodeString(from: container, forKey: .test)
    }

    private static func decodeString(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws -> String {
        try container.decodeIfPresent(String.self, forKey: key) ?? ""
    }
}
