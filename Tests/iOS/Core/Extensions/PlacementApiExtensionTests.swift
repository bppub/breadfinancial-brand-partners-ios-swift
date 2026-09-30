import Foundation
import Testing

@testable import BreadPartners

@Suite
@MainActor
struct PlacementApiExtensionTests {
    @Test
    func fetchBrandConfigStoresDecodedResponse() async throws {
        let httpClient = HTTPClientSpy(outcomes: [.success(brandConfigurationData)])
        let sdk = BreadPartnersSDK()
        sdk.integrationKey = "brand-key"

        await sdk.fetchBrandConfig(httpClient: httpClient)

        #expect(sdk.brandConfiguration?.config.clientName == "test-client")
        #expect(await httpClient.requestCount == 1)
    }

    @Test
    func fetchBrandConfigLeavesConfigurationUnsetWhenRequestFails() async {
        let httpClient = HTTPClientSpy(outcomes: [.failure(testError)])
        let sdk = BreadPartnersSDK()
        sdk.brandConfiguration = nil
        sdk.integrationKey = "brand-key"

        await sdk.fetchBrandConfig(httpClient: httpClient)

        #expect(sdk.brandConfiguration == nil)
    }

    @Test
    func fetchBrandConfigLeavesConfigurationUnsetWhenResponseIsMalformed() async {
        let httpClient = HTTPClientSpy(outcomes: [.success(Data("invalid-json".utf8))])
        let sdk = BreadPartnersSDK()
        sdk.integrationKey = "brand-key"

        await sdk.fetchBrandConfig(httpClient: httpClient)

        #expect(sdk.brandConfiguration == nil)
        #expect(await httpClient.requestCount == 1)
    }

    private var brandConfigurationData: Data {
        Data(
            """
            {"config":{"clientName":"test-client"}}
            """.utf8
        )
    }

    private var testError: NSError {
        NSError(domain: "PlacementApiExtensionTests", code: 1)
    }
}
