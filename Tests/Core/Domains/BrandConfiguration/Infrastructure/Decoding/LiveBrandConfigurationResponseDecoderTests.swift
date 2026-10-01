import Foundation
import Testing

@testable import BreadPartnersCore

@Suite
struct BrandConfigurationDecoderTests {
    @Test
    func decodeMapsRecaptchaSiteKeys() throws {
        let data = Data(
            #"{"config":{"rsk_UAT_NATIVE_IOS":"uat-key","rsk_STAGE_NATIVE_IOS":"stage-key","rsk_PROD_NATIVE_IOS":"production-key"}}"#
                .utf8
        )

        let configuration = try LiveBrandConfigurationResponseDecoder().decode(
            from: data
        )

        #expect(configuration.uatRecaptchaSiteKey == "uat-key")
        #expect(configuration.stageRecaptchaSiteKey == "stage-key")
        #expect(configuration.productionRecaptchaSiteKey == "production-key")
    }

    @Test
    func decodeDefaultsMissingSiteKeysToEmptyStrings() throws {
        let data = Data(#"{"config":{}}"#.utf8)

        let configuration = try LiveBrandConfigurationResponseDecoder().decode(
            from: data
        )

        #expect(configuration.uatRecaptchaSiteKey.isEmpty)
        #expect(configuration.stageRecaptchaSiteKey.isEmpty)
        #expect(configuration.productionRecaptchaSiteKey.isEmpty)
    }

    @Test
    func decodeDefaultsNullSiteKeysAndIgnoresOtherLegacyConfigFields() throws {
        let data = Data(
            #"{"config":{"AEMContent":null,"clientName":"client","rsk_UAT_NATIVE_ANDROID":"android-key","rsk_UAT_NATIVE_IOS":null,"rsk_STAGE_NATIVE_IOS":null,"rsk_PROD_NATIVE_IOS":null}}"#
                .utf8
        )

        let configuration = try LiveBrandConfigurationResponseDecoder().decode(
            from: data
        )

        #expect(configuration.uatRecaptchaSiteKey.isEmpty)
        #expect(configuration.stageRecaptchaSiteKey.isEmpty)
        #expect(configuration.productionRecaptchaSiteKey.isEmpty)
    }

    @Test(arguments: [
        "AEMContent",
        "OVERRIDE_KEY",
        "clientName",
        "prodAdServerUrl",
        "qaAdServerUrl",
        "recaptchaEnabledQA",
        "recaptchaSiteKeyQA",
        "recaptchaSiteKeyPROD",
        "recaptchaEnabledPROD",
        "rsk_UAT_NATIVE_IOS",
        "rsk_UAT_NATIVE_ANDROID",
        "rsk_STAGE_NATIVE_IOS",
        "rsk_STAGE_NATIVE_ANDROID",
        "rsk_PROD_NATIVE_IOS",
        "rsk_PROD_NATIVE_ANDROID",
        "test",
    ])
    func decodeThrowsForNonStringLegacyConfigField(key: String) throws {
        let data = try JSONSerialization.data(
            withJSONObject: ["config": [key: 42]]
        )

        #expect(throws: DecodingError.self) {
            try LiveBrandConfigurationResponseDecoder().decode(from: data)
        }
    }

    @Test(arguments: [
        Data("invalid-json".utf8),
        Data(#"{"unexpected":{}}"#.utf8),
    ])
    func decodeThrowsForInvalidResponse(data: Data) {
        #expect(throws: DecodingError.self) {
            try LiveBrandConfigurationResponseDecoder().decode(from: data)
        }
    }
}
