import Foundation
import Testing

@testable import BreadPartnersCore

@Suite
struct BrandConfigurationServiceTests {
    @Test
    func fetchRequestsEndpointAndReturnsDecodedConfiguration() async throws {
        let expectedConfiguration = BrandConfiguration.fixture
        let httpClient = HTTPClientSpy(responseData: Data("response".utf8))
        let endpointProvider = LiveAPIEndpointProvider(environment: .stage)
        let service = BrandConfigurationService(
            dependencies: BrandConfigurationDependencies(
                httpClient: httpClient,
                endpointProvider: endpointProvider,
                responseDecoder: BrandConfigurationResponseDecoderStub(
                    result: .success(expectedConfiguration)
                )
            )
        )

        let configuration = await service.fetch(brandID: "brand-key")

        #expect(configuration == expectedConfiguration)
        let request = try #require(await httpClient.requests.first)
        #expect(request.method == .GET)
        #expect(
            request.url
                == endpointProvider.url(for: .brandConfig(brandId: "brand-key"))
        )
    }

    @Test
    func fetchReturnsNilForHTTPError() async {
        let service = makeService(
            httpClient: HTTPClientSpy(
                failure: NSError(domain: "BrandConfiguration", code: 1)
            ),
            decodeResult: .success(.fixture)
        )

        #expect(await service.fetch(brandID: "brand-key") == nil)
    }

    @Test
    func fetchReturnsNilForDecodingError() async {
        let service = makeService(
            httpClient: HTTPClientSpy(),
            decodeResult: .failure(NSError(domain: "Decoding", code: 1))
        )

        #expect(await service.fetch(brandID: "brand-key") == nil)
    }

    private func makeService(
        httpClient: HTTPClientSpy,
        decodeResult: Result<BrandConfiguration, NSError>
    ) -> BrandConfigurationService {
        BrandConfigurationService(
            dependencies: BrandConfigurationDependencies(
                httpClient: httpClient,
                endpointProvider: LiveAPIEndpointProvider(environment: .stage),
                responseDecoder: BrandConfigurationResponseDecoderStub(
                    result: decodeResult
                )
            )
        )
    }
}

private final class BrandConfigurationResponseDecoderStub:
    BrandConfigurationResponseDecoding, @unchecked Sendable
{
    private let result: Result<BrandConfiguration, NSError>

    init(result: Result<BrandConfiguration, NSError>) {
        self.result = result
    }

    func decode(from data: Data) throws -> BrandConfiguration {
        try result.get()
    }
}

private extension BrandConfiguration {
    static let fixture = BrandConfiguration(
        uatRecaptchaSiteKey: "uat-key",
        stageRecaptchaSiteKey: "stage-key",
        productionRecaptchaSiteKey: "production-key"
    )
}
