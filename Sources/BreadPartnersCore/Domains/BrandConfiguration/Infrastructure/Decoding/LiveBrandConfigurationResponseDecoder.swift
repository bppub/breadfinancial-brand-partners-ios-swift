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
    let uatRecaptchaSiteKey: String
    let stageRecaptchaSiteKey: String
    let productionRecaptchaSiteKey: String

    private enum CodingKeys: String, CodingKey {
        case uatRecaptchaSiteKey = "rsk_UAT_NATIVE_IOS"
        case stageRecaptchaSiteKey = "rsk_STAGE_NATIVE_IOS"
        case productionRecaptchaSiteKey = "rsk_PROD_NATIVE_IOS"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uatRecaptchaSiteKey =
            try container.decodeIfPresent(
                String.self,
                forKey: .uatRecaptchaSiteKey
            ) ?? ""
        stageRecaptchaSiteKey =
            try container.decodeIfPresent(
                String.self,
                forKey: .stageRecaptchaSiteKey
            ) ?? ""
        productionRecaptchaSiteKey =
            try container.decodeIfPresent(
                String.self,
                forKey: .productionRecaptchaSiteKey
            ) ?? ""
    }
}
