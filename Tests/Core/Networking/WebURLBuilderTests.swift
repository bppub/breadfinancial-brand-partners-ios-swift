import Foundation
import Testing
@testable import BreadPartnersCore

@Suite
struct WebURLBuilderTests {
    @Test
    func buildsRTPSWebURLWithoutRTPSData() {
        let url = WebURLBuilder.buildRTPSWebURL(
            environment: .prod,
            integrationKey: "integration-key",
            merchantConfiguration: MerchantConfiguration(),
            rtpsData: nil
        )

        #expect(url != nil)
        #expect(url?.query?.contains("prescreenId") == false)
    }

    @Test
    func buildsRTPSURLWithAllSupportedValues() throws {
        let buyer = BreadPartnersBuyer(
            givenName: "Ada",
            familyName: "Lovelace",
            email: "ada@example.com",
            phone: "555-0100",
            alternativePhone: "555-0101",
            billingAddress: BreadPartnersAddress(
                address1: "1 Main Street",
                locality: "Columbus",
                region: "OH",
                postalCode: "43004"
            )
        )
        let merchantConfiguration = MerchantConfiguration(
            buyer: buyer,
            storeNumber: "store-1"
        )
        let rtpsData = RTPSData(
            locationType: .checkout,
            cardType: "storeCard",
            prescreenId: 42,
            channel: "web",
            mockResponse: .success
        )

        let url = try #require(
            WebURLBuilder.buildRTPSWebURL(
                environment: .stage,
                integrationKey: "integration-key",
                merchantConfiguration: merchantConfiguration,
                rtpsData: rtpsData
            )
        )
        let query = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        let values: [String: String?] = Dictionary(
            uniqueKeysWithValues: query.map { ($0.name, $0.value) }
        )

        #expect(url.host == "acquire1stage.comenity.net")
        #expect(values["clientKey"] == "integration-key")
        #expect(values["mockMO"] == "success")
        #expect(values["cardType"] == "storeCard")
        #expect(values["prescreenId"] == "42")
        #expect(values["firstName"] == "Ada")
        #expect(values["address1"] == "1 Main Street")
        #expect(values["location"] == "checkout")
        #expect(values["alternativePhone"] == "555-0101")
    }

    @Test
    func filtersNilAndBlankRTPSValues() throws {
        let url = try #require(
            WebURLBuilder.buildRTPSWebURL(
                environment: .prod,
                integrationKey: "",
                merchantConfiguration: MerchantConfiguration(),
                rtpsData: nil
            )
        )
        let query = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        let names = Set(query.map(\.name))

        #expect(names.contains("embedded"))
        #expect(names.contains("clientKey") == false)
        #expect(names.contains("prescreenId") == false)
        #expect(names.contains("mockMO") == false)
    }

    @Test
    func buildsBPSURLWithRTPSValuesTakingPrecedence() throws {
        let merchantConfiguration = MerchantConfiguration(
            channel: "merchant-channel",
            subchannel: "merchant-subchannel"
        )
        let rtpsData = RTPSData(
            order: Order(),
            locationType: .checkout,
            channel: "rtps-channel",
            subChannel: "rtps-subchannel"
        )
        let placementData = PlacementData(
            locationType: .homepage,
            order: Order()
        )
        placementData.defaultSelectedCardKey = "default"
        placementData.selectedCardKey = "selected"

        let url = try #require(
            WebURLBuilder.buildBPSWebURL(
                environment: .uat,
                integrationKey: "integration-key",
                rtpsData: rtpsData,
                placementData: placementData,
                merchantConfiguration: merchantConfiguration
            )
        )
        let query = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        let values: [String: String?] = Dictionary(
            uniqueKeysWithValues: query.map { ($0.name, $0.value) }
        )

        #expect(url.host == "acquire1uat.comenity.net")
        #expect(values["location"] == "checkout")
        #expect(values["channel"] == "rtps-channel")
        #expect(values["subchannel"] == "rtps-subchannel")
        #expect(values["selectedCardKey"] == "selected")
        #expect(values["defaultSelectedCardKey"] == "default")
    }

    @Test
    func buildsBPSURLWithPlacementAndMerchantFallbacks() throws {
        let merchantConfiguration = MerchantConfiguration(
            channel: "merchant-channel",
            subchannel: "merchant-subchannel"
        )
        let placementData = PlacementData(locationType: .homepage)
        placementData.defaultSelectedCardKey = "default"
        placementData.selectedCardKey = "selected"

        let url = try #require(
            WebURLBuilder.buildBPSWebURL(
                environment: .prod,
                integrationKey: "integration-key",
                rtpsData: nil,
                placementData: placementData,
                merchantConfiguration: merchantConfiguration
            )
        )
        let query = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        let values: [String: String?] = Dictionary(
            uniqueKeysWithValues: query.map { ($0.name, $0.value) }
        )

        #expect(values["location"] == "homepage")
        #expect(values["channel"] == "merchant-channel")
        #expect(values["subchannel"] == "merchant-subchannel")
        #expect(values["selectedCardKey"] == "selected")
    }
}
