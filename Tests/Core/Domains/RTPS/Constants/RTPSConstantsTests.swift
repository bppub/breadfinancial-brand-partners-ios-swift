import Testing
@testable import BreadPartnersCore

@Suite
struct RTPSConstantsTests {
    @Test
    func preservesRTPSRequestHeadersAndRecaptchaConfiguration() {
        #expect(RTPSRequestHeaders.clientKey == "X-Client-Key")
        #expect(RTPSRequestHeaders.requestedWith == "X-Requested-With")
        #expect(RTPSRequestHeaders.xmlHttpRequest == "XMLHttpRequest")
        #expect(RTPSRecaptcha.action == "checkout")
        #expect(RTPSRecaptcha.timeout == 10000)
    }

    @Test
    func preservesIncapsulaChallengeMetadata() {
        #expect(NetworkChallengeConstants.domain == "IncapsulaChallenge")
        #expect(NetworkChallengeConstants.htmlContentKey == "htmlContent")
        #expect(NetworkChallengeConstants.urlKey == "url")
    }

    @Test
    func formatsRTPSApiErrors() {
        #expect(RTPSConstants.error == "Error:")
        #expect(RTPSConstants.apiError(message: "request failed") == "Error: request failed")
        #expect(RTPSConstants.catchError(message: "decoding failed") == "Error: decoding failed")
    }

    @Test
    func preservesPrescreenRequiredFieldsError() {
        #expect(
            RTPSConstants.prescreenRequiredFieldsError
                == "Error: Prescreen requires customer information: firstname, lastname, and complete billing address must be provided in MerchantConfiguration."
        )
    }
}
