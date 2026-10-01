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
