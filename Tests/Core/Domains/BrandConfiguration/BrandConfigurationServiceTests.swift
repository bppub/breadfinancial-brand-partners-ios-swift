//------------------------------------------------------------------------------
//  File:          BrandConfigurationServiceTests.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import BreadPartnersTestSupport
import Foundation
import Testing

@testable import BreadPartnersCore

@Suite
struct BrandConfigurationServiceTests {
    @Test
    func fetchRequestsEndpointAndReturnsDecodedConfiguration() async throws {
        let expectedConfiguration = BrandConfiguration.fixture
        let httpClient = HTTPClientSpy(outcomes: [.success(Data("response".utf8))])
        let endpointProvider = LiveAPIEndpointProvider(environment: .stage)
        let service = BrandConfigurationService(
            dependencies: BrandConfigurationDependencies(
                endpointProvider: endpointProvider,
                responseDecoder: BrandConfigurationResponseDecoderStub(
                    result: .success(expectedConfiguration)
                )
            )
        )

        let configuration = await service.fetch(brandID: "brand-key", httpClient: httpClient)

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
            decodeResult: .success(.fixture)
        )

        #expect(
            await service.fetch(
                brandID: "brand-key",
                httpClient: HTTPClientSpy(
                    outcomes: [.failure(NSError(domain: "BrandConfiguration", code: 1))]
                )
            ) == nil
        )
    }

    @Test
    func fetchReturnsNilForDecodingError() async {
        let service = makeService(
            decodeResult: .failure(NSError(domain: "Decoding", code: 1))
        )

        #expect(
            await service.fetch(
                brandID: "brand-key",
                httpClient: HTTPClientSpy(outcomes: [.success(Data())])
            ) == nil
        )
    }

    private func makeService(
        decodeResult: Result<BrandConfiguration, NSError>
    ) -> BrandConfigurationService {
        BrandConfigurationService(
            dependencies: BrandConfigurationDependencies(
                endpointProvider: LiveAPIEndpointProvider(environment: .stage),
                responseDecoder: BrandConfigurationResponseDecoderStub(
                    result: decodeResult
                )
            )
        )
    }

    @Test
    func initializerDefaultsToLiveDecoder() async {
        let service = BrandConfigurationService(
            dependencies: BrandConfigurationDependencies(
                endpointProvider: LiveAPIEndpointProvider(environment: .stage)
            )
        )
        let httpClient = HTTPClientSpy(
            outcomes: [.success(Data(#"{"config":{"rsk_STAGE_NATIVE_IOS":"stage-key"}}"#.utf8))]
        )

        let configuration = await service.fetch(
            brandID: "brand-key",
            httpClient: httpClient
        )

        #expect(configuration?.stageRecaptchaSiteKey == "stage-key")
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
