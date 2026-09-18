import Testing

@testable import BreadPartnersCore

@Suite struct RTPSPrescreenValidatorTests {
    @Test
    func acceptsCompleteBuyerInformation() {
        #expect(
            RTPSPrescreenValidator.hasRequiredFields(
                in: RTPSFixtures.MerchantConfigurationFixture.complete()
            )
        )
    }

    @Test(arguments: RTPSFixtures.MerchantConfigurationFixture.RequiredField.allCases)
    func rejectsEmptyRequiredField(
        field: RTPSFixtures.MerchantConfigurationFixture.RequiredField
    ) {
        let configuration = RTPSFixtures.MerchantConfigurationFixture.missing(field)
        #expect(RTPSPrescreenValidator.hasRequiredFields(in: configuration) == false)
    }

    @Test
    func rejectsMissingBuyer() {
        #expect(RTPSPrescreenValidator.hasRequiredFields(in: MerchantConfiguration()) == false)
    }

    @Test
    func rejectsMissingBillingAddress() {
        let configuration = MerchantConfiguration(
            buyer: BreadPartnersBuyer(givenName: "Ada", familyName: "Lovelace")
        )
        #expect(RTPSPrescreenValidator.hasRequiredFields(in: configuration) == false)
    }
}
