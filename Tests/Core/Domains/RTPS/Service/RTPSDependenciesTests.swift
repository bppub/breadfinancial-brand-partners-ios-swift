import Foundation
import Testing
@testable import BreadPartnersCore

@Suite struct RTPSDependenciesTests {
    @Test
    func storesInjectedDependencies() {
        let recaptcha = StubRecaptchaProvider()
        let requestBuilder = StubRTPSRequestBuilder()
        let responseDecoder = StubRTPSResponseDecoder()

        let dependencies = RTPSDependencies(
            recaptcha: recaptcha,
            requestBuilder: requestBuilder,
            responseDecoder: responseDecoder
        )

        #expect(dependencies.recaptcha is StubRecaptchaProvider)
        #expect(dependencies.requestBuilder is StubRTPSRequestBuilder)
        #expect(dependencies.responseDecoder is StubRTPSResponseDecoder)
    }
}
