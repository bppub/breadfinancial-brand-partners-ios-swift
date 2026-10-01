struct BrandConfiguration: Equatable, Sendable {
    let uatRecaptchaSiteKey: String
    let stageRecaptchaSiteKey: String
    let productionRecaptchaSiteKey: String

    func recaptchaSiteKey(for environment: BreadPartnersEnvironment) -> String {
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
