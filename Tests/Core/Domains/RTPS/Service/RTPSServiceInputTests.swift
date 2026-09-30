import Foundation
import Testing

@testable import BreadPartnersCore

@Suite struct RTPSServiceInputTests {
    @Test
    func initializesAllValues() {
        let log = LogCapture()
        let merchantConfiguration = RTPSFixtures.MerchantConfigurationFixture.complete()
        let rtpsData = RTPSData(prescreenId: 42)
        let prescreenURL = URL(string: "https://prescreen.test")!
        let virtualLookupURL = URL(string: "https://lookup.test")!

        let input = RTPSServiceInput(
            merchantConfiguration: merchantConfiguration,
            rtpsData: rtpsData,
            integrationKey: "integration-key",
            siteKey: "site-key",
            prescreenURL: prescreenURL,
            virtualLookupURL: virtualLookupURL,
            cookies: "visid=abc",
            isLoggingEnabled: true,
            log: log.record
        )

        #expect(input.merchantConfiguration.storeNumber == merchantConfiguration.storeNumber)
        #expect(input.rtpsData === rtpsData)
        #expect(input.integrationKey == "integration-key")
        #expect(input.siteKey == "site-key")
        #expect(input.prescreenURL == prescreenURL)
        #expect(input.virtualLookupURL == virtualLookupURL)
        #expect(input.cookies == "visid=abc")
        #expect(input.isLoggingEnabled)

        input.log("message")

        #expect(log.recordedMessages == ["message"])
    }

    @Test
    func defaultsOptionalValuesAndLog() {
        let input = RTPSServiceInput(
            merchantConfiguration: MerchantConfiguration(),
            rtpsData: RTPSData(),
            integrationKey: "integration-key",
            siteKey: "site-key",
            prescreenURL: RTPSFixtures.URLs.prescreen,
            virtualLookupURL: RTPSFixtures.URLs.virtualLookup
        )

        input.log("confirm default no-op closure is initialized")

        #expect(input.isLoggingEnabled == false)
        #expect(input.cookies == nil)
    }
}
