import Testing
@testable import BreadPartners

@Suite struct WebURLBuilderTests {
    @Test
    func buildsRTPSWebURLWithoutRTPSData() {
        let url = WebURLBuilder.buildRTPSWebURL(
            integrationKey: "integration-key",
            merchantConfiguration: MerchantConfiguration(),
            rtpsData: nil
        )

        #expect(url != nil)
        #expect(url?.query?.contains("prescreenId") == false)
    }
}
