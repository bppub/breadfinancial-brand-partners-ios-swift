import Testing
@testable import BreadPartnersCore

@Suite struct RTPSRequestBuilderTests {
    @Test
    func buildsPrescreenRequestWithToken() {
        let buyer = BreadPartnersBuyer(
            givenName: "Ada",
            familyName: "Lovelace",
            email: "ada@example.com"
        )
        let merchant = MerchantConfiguration(buyer: buyer)
        let data = RTPSData(screenName: "checkout")
        let request = RTPSRequestBuilder().build(
            merchantConfiguration: merchant,
            rtpsData: data,
            recaptchaToken: "token"
        )

        #expect(request.firstName == "Ada")
        #expect(request.lastName == "Lovelace")
        #expect(request.emailAddress == "ada@example.com")
        #expect(request.reCaptchaToken == "token")
        #expect(request.prescreenId == nil)
    }

    @Test
    func buildsVirtualLookupWithoutPrescreenFields() {
        let merchant = MerchantConfiguration(
            buyer: BreadPartnersBuyer(givenName: "Ada"),
            channel: "online"
        )
        let data = RTPSData(prescreenId: 42)
        let request = RTPSRequestBuilder().build(
            merchantConfiguration: merchant,
            rtpsData: data,
            recaptchaToken: "ignored"
        )

        #expect(request.prescreenId == "42")
        #expect(request.firstName == nil)
        #expect(request.reCaptchaToken == nil)
        #expect(request.channel == "online")
    }
}
