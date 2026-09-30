import Foundation
import Testing

@testable import BreadPartners

@Suite
struct LiveBrandConfigurationServiceTests {
    @Test
    func fetchRequestsEndpointAndMapsConfiguration() async throws {
        let httpClient = HTTPClientSpy(outcomes: [.success(completeResponse)])
        let endpointProvider = LiveAPIEndpointProvider(environment: .stage)
        let service = LiveBrandConfigurationService(
            httpClient: httpClient,
            endpointProvider: endpointProvider
        )

        let configuration = try #require(await service.fetch(brandID: "brand-key"))

        #expect(configuration.uatRecaptchaSiteKey == "uat-key")
        #expect(configuration.stageRecaptchaSiteKey == "stage-key")
        #expect(configuration.productionRecaptchaSiteKey == "production-key")
        let request = try #require(await httpClient.requests.first)
        #expect(request.method == .GET)
        #expect(
            request.url
                == endpointProvider.url(for: .brandConfig(brandId: "brand-key"))
        )
    }

    @Test
    func fetchDefaultsMissingSiteKeysToEmptyStrings() async throws {
        let service = makeService(response: Data(#"{"config":{}}"#.utf8))

        let configuration = try #require(await service.fetch(brandID: "brand-key"))

        #expect(configuration.uatRecaptchaSiteKey.isEmpty)
        #expect(configuration.stageRecaptchaSiteKey.isEmpty)
        #expect(configuration.productionRecaptchaSiteKey.isEmpty)
    }

    @Test(arguments: [
        Data("invalid-json".utf8),
        Data(#"{"unexpected":{}}"#.utf8),
    ])
    func fetchReturnsNilForInvalidResponse(response: Data) async {
        let service = makeService(response: response)

        #expect(await service.fetch(brandID: "brand-key") == nil)
    }

    @Test
    func fetchReturnsNilForHTTPError() async {
        let httpClient = HTTPClientSpy(
            outcomes: [.failure(NSError(domain: "BrandConfiguration", code: 1))]
        )
        let service = LiveBrandConfigurationService(
            httpClient: httpClient,
            endpointProvider: LiveAPIEndpointProvider(environment: .stage)
        )

        #expect(await service.fetch(brandID: "brand-key") == nil)
    }

    private func makeService(response: Data) -> LiveBrandConfigurationService {
        LiveBrandConfigurationService(
            httpClient: HTTPClientSpy(outcomes: [.success(response)]),
            endpointProvider: LiveAPIEndpointProvider(environment: .stage)
        )
    }

    private var completeResponse: Data {
        Data(
            #"{"config":{"rsk_UAT_NATIVE_IOS":"uat-key","rsk_STAGE_NATIVE_IOS":"stage-key","rsk_PROD_NATIVE_IOS":"production-key"}}"#
                .utf8
        )
    }
}
