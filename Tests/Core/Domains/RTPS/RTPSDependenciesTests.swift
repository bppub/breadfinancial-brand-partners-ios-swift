import Foundation
import Testing
@testable import BreadPartnersCore

@Suite struct RTPSDependenciesTests {
    @Test
    func storesInjectedDependencies() {
        let recaptcha = StubRecaptchaProvider()
        let network = SpyRTPSNetworkClient()
        let requestBuilder = StubRTPSRequestBuilder()
        let responseDecoder = StubRTPSResponseDecoder()

        let dependencies = RTPSDependencies(
            recaptcha: recaptcha,
            network: network,
            requestBuilder: requestBuilder,
            responseDecoder: responseDecoder
        )

        #expect(dependencies.recaptcha is StubRecaptchaProvider)
        #expect(dependencies.network is SpyRTPSNetworkClient)
        #expect(dependencies.requestBuilder is StubRTPSRequestBuilder)
        #expect(dependencies.responseDecoder is StubRTPSResponseDecoder)
    }
}
