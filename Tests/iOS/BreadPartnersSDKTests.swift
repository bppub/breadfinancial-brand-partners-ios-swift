import BreadPartnersTestSupport
import Foundation
import Testing
import BreadPartnersCore
import XCTest

@testable import BreadPartners

@Suite(.serialized)
@MainActor
struct BreadPartnersSDKTests {
    @Test
    func sharedReturnsSameSDKInstance() {
        #expect(BreadPartnersSDK.shared === BreadPartnersSDK.shared)
    }

    @Test
    func clientFacingSetupBuildsLiveDependencies() async throws {
        let sdk = BreadPartnersSDK()

        await sdk.setup(
            environment: .stage,
            integrationKey: "",
            enableLog: true
        )

        let dependencies = try #require(sdk.dependencies)
        #expect(dependencies.environment == .stage)
        #expect(dependencies.httpClientFactory is LiveHTTPClientFactory)
        #expect(dependencies.endpointProvider is LiveAPIEndpointProvider)
        #expect(dependencies.rtpsCoordinator is RTPSCoordinator)
        #expect(sdk.integrationKey.isEmpty)
        #expect(sdk.isLoggingEnabled)
    }

    @Test
    func setupBuildsDependenciesAndFetchesBrandConfiguration() async throws {
        let httpClient = HTTPClientSpy()
        let service = BrandConfigurationServiceSpy(results: [brandConfiguration])
        let dependencies = makeDependencies(
            httpClient: httpClient,
            brandConfigurationService: service
        )
        let sdk = BreadPartnersSDK()

        await sdk.setup(
            environment: .stage,
            integrationKey: "brand-key",
            enableLog: true,
            dependencies: dependencies
        )

        #expect(sdk.dependencies?.environment == .stage)
        #expect(sdk.integrationKey == "brand-key")
        #expect(sdk.isLoggingEnabled)
        #expect(sdk.dependencies != nil)
        #expect(sdk.brandConfiguration?.stageRecaptchaSiteKey == "stage-key")
        #expect(await service.requestedBrandIDs == ["brand-key"])
        #expect(await httpClient.requestCount == 0)
    }

    @Test
    func silentRTPSRequestReportsErrorBeforeSetup() async {
        let sdk = BreadPartnersSDK()
        let events = EventCapture()

        await sdk.silentRTPSRequest(
            merchantConfiguration: RTPSTestFixtures.MerchantConfigurationFixture.complete,
            placementsConfiguration: PlacementConfiguration(),
            callback: events.record
        )

        #expect(events.containsSDKError)
    }

    @Test
    func silentRTPSRequestCreatesCoordinatorWithActionDependencies() async throws {
        let httpClient = HTTPClientSpy()
        let service = BrandConfigurationServiceSpy(results: [brandConfiguration])
        let coordinator = RootCoordinatorSpy()
        let dependencies = makeDependencies(
            httpClient: httpClient,
            coordinator: coordinator,
            brandConfigurationService: service
        )
        let sdk = BreadPartnersSDK()
        let events = EventCapture()

        await sdk.setup(
            environment: .stage,
            integrationKey: "brand-key",
            enableLog: true,
            dependencies: dependencies
        )
        await sdk.silentRTPSRequest(
            merchantConfiguration: RTPSTestFixtures.MerchantConfigurationFixture.complete,
            placementsConfiguration: PlacementConfiguration(),
            splitTextAndAction: true,
            forSwiftUI: true,
            callback: events.record
        )

        let input = try #require(await coordinator.lastInput)
        #expect(input.integrationKey == "brand-key")
        #expect(input.brandConfiguration?.stageRecaptchaSiteKey == "stage-key")
        #expect(input.splitTextAndAction)
        #expect(input.forSwiftUI)
        #expect(input.placementsConfiguration.popUpStyling != nil)
        #expect(await service.requestedBrandIDs == ["brand-key"])
        #expect((dependencies.httpClientFactory as? HTTPClientFactorySpy)?.makeCount == 2)
        #expect(await coordinator.runCount == 1)
        #expect(events.eventCount > 0)
    }

    @Test
    func silentRTPSRequestLazilyFetchesBrandConfiguration() async throws {
        let httpClient = HTTPClientSpy()
        let service = BrandConfigurationServiceSpy(results: [nil, brandConfiguration])
        let coordinator = RootCoordinatorSpy()
        let dependencies = makeDependencies(
            httpClient: httpClient,
            coordinator: coordinator,
            brandConfigurationService: service
        )
        let sdk = BreadPartnersSDK()

        await sdk.setup(
            environment: .stage,
            integrationKey: "brand-key",
            enableLog: false,
            dependencies: dependencies
        )

        await sdk.silentRTPSRequest(
            merchantConfiguration: RTPSTestFixtures.MerchantConfigurationFixture.complete,
            placementsConfiguration: PlacementConfiguration(),
            callback: { _ in }
        )

        #expect(sdk.brandConfiguration != nil)
        #expect(sdk.brandConfiguration?.stageRecaptchaSiteKey == "stage-key")
        let input = try #require(await coordinator.lastInput)
        #expect(input.brandConfiguration?.stageRecaptchaSiteKey == "stage-key")
        #expect(await service.requestedBrandIDs == ["brand-key", "brand-key"])
        #expect(await httpClient.requestCount == 0)
        #expect((dependencies.httpClientFactory as? HTTPClientFactorySpy)?.makeCount == 2)
    }

    @Test
    func placementRendererUsesSDKHTTPFactoryAndEndpointsForAnalytics() async throws {
        let httpClient = HTTPClientSpy(outcomes: [.success(Data())])
        let reported = XCTestExpectation(description: "analytics sent through SDK HTTP client")
        let observedClient = AnalyticsHTTPClientObserver(client: httpClient, reported: reported)
        let endpoint = try #require(URL(string: "https://sdk-analytics.test/view"))
        let endpointProvider = SDKAnalyticsEndpointProvider(url: endpoint)
        let dependencies = makeDependencies(
            httpClient: observedClient,
            brandConfigurationService: BrandConfigurationServiceSpy(results: [brandConfiguration]),
            endpointProvider: SDKAnalyticsEndpointProvider(url: endpoint.appendingPathComponent("unexpected")),
            analyticsFactory: LiveAnalyticsReporterFactory(
                endpointProvider: endpointProvider
            )
        )
        let sdk = BreadPartnersSDK()
        await sdk.setup(environment: .stage, integrationKey: "brand", enableLog: false, dependencies: dependencies)
        let events = EventCapture()
        let logger = Logger()
        let response: [String: Any] = [
            "placementContent": [
                [
                    "id": "text",
                    "contentData": [
                        "htmlContent": "<div class='ep-text-placement'><div class='epjs-body'>Offer</div></div>"
                    ],
                ]
            ]
        ]

        await sdk.handlePlacementResponse(
            AnySendable(value: response), merchantConfiguration: MerchantConfiguration(),
            placementsConfiguration: PlacementConfiguration(), logger: logger, callback: events.record
        )

        #expect(await XCTWaiter.fulfillment(of: [reported], timeout: 2) == .completed)
        let requests = await httpClient.requests
        #expect(requests.count == 1)
        #expect(requests.first?.url == endpoint)
        #expect(requests.first?.method == .OPTIONS)
        let payload = try JSONDecoder().decode(Analytics.Payload.self, from: #require(requests.first?.body))
        #expect(payload.name == "view-placement")
        #expect(payload.context?.apiKey == "")
        #expect((dependencies.httpClientFactory as? HTTPClientFactorySpy)?.makeCount == 2)
        #expect((dependencies.httpClientFactory as? HTTPClientFactorySpy)?.lastLogger === logger)
        #expect(events.eventCount == 1)
        guard case .renderTextViewWithLink = try #require(events.first) else {
            Issue.record("Expected the original text render callback")
            return
        }
    }

    private func makeDependencies(
        httpClient: any HTTPClient,
        coordinator: RootCoordinatorSpy = RootCoordinatorSpy(),
        brandConfigurationService serviceSpy: BrandConfigurationServiceSpy? = nil,
        endpointProvider: any APIEndpointProviding = LiveAPIEndpointProvider(environment: .stage),
        analyticsFactory: (any AnalyticsReporterFactory)? = nil
    ) -> SDKDependencies {
        let brandConfigurationService: any BrandConfigurationServicing
        if let serviceSpy {
            brandConfigurationService = serviceSpy
        } else {
            brandConfigurationService = BrandConfigurationService(
                dependencies: BrandConfigurationDependencies(
                    endpointProvider: endpointProvider
                )
            )
        }

        return SDKDependencies(
            environment: .stage,
            httpClientFactory: HTTPClientFactorySpy(client: httpClient),
            endpointProvider: endpointProvider,
            brandConfigurationService: brandConfigurationService,
            placementService: LivePlacementService(),
            analyticsFactory: analyticsFactory
                ?? LiveAnalyticsReporterFactory(
                    endpointProvider: endpointProvider
                ),
            rtpsCoordinator: coordinator
        )
    }

    private var brandConfiguration: BrandConfiguration {
        BrandConfiguration(
            uatRecaptchaSiteKey: "uat-key",
            stageRecaptchaSiteKey: "stage-key",
            productionRecaptchaSiteKey: "production-key"
        )
    }
}

private final class HTTPClientFactorySpy: HTTPClientFactory, @unchecked Sendable {
    let client: any HTTPClient
    private(set) var makeCount = 0
    private(set) var lastLogger: Logger?

    init(client: any HTTPClient) {
        self.client = client
    }

    func makeClient(logger: Logger) -> any HTTPClient {
        makeCount += 1
        lastLogger = logger
        return client
    }
}

struct AnalyticsHTTPClientObserver: HTTPClient {
    let client: HTTPClientSpy
    let reported: XCTestExpectation

    func request(_ request: HTTPRequest) async throws -> Data {
        defer { reported.fulfill() }
        return try await client.request(request)
    }
}

private struct SDKAnalyticsEndpointProvider: APIEndpointProviding {
    let url: URL

    func url(for endpoint: APIEndpoint) -> URL {
        switch endpoint {
        case .viewPlacement: url
        default: url.appendingPathComponent("unexpected")
        }
    }
}

private actor RootCoordinatorSpy: RealTimePrescreenCoordinating {
    private(set) var lastInput: RealTimePrescreenInput?
    private(set) var runCount = 0

    func runFlow(_ input: RealTimePrescreenInput) async {
        runCount += 1
        lastInput = input
        input.logger.debugPrint("root SDK test event")
    }
}
