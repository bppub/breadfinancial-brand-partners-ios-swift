import BreadPartnersTestSupport
import Foundation
import Testing
import BreadPartnersCore

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

    private func makeDependencies(
        httpClient: HTTPClientSpy,
        coordinator: RootCoordinatorSpy = RootCoordinatorSpy(),
        brandConfigurationService serviceSpy: BrandConfigurationServiceSpy? = nil
    ) -> SDKDependencies {
        let endpointProvider = LiveAPIEndpointProvider(environment: .stage)
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
            analyticsFactory: LiveAnalyticsReporterFactory(endpointProvider: endpointProvider),
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

    init(client: any HTTPClient) {
        self.client = client
    }

    func makeClient(logger: Logger) -> any HTTPClient {
        makeCount += 1
        return client
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
