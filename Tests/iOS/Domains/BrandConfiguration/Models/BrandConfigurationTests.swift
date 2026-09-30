import Testing

@testable import BreadPartners

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
