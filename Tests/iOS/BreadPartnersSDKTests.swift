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
        #expect(dependencies.httpClientFactory is LiveHTTPClientFactory)
        #expect(dependencies.endpointProvider is LiveAPIEndpointProvider)
        #expect(dependencies.rtpsCoordinatorFactory is LiveRTPSCoordinatorFactory)
        #expect(sdk.sdkEnvironment == .stage)
        #expect(sdk.integrationKey.isEmpty)
        #expect(sdk.isLoggingEnabled)
    }

    @Test
    func setupBuildsDependenciesAndFetchesBrandConfiguration() async throws {
        let httpClient = HTTPClientSpy(outcomes: [.success(brandConfigurationData)])
        let dependencies = makeDependencies(httpClient: httpClient)
        let sdk = BreadPartnersSDK()

        await sdk.setup(
            environment: .stage,
            integrationKey: "brand-key",
            enableLog: true,
            dependencies: dependencies
        )

        #expect(sdk.sdkEnvironment == .stage)
        #expect(sdk.integrationKey == "brand-key")
        #expect(sdk.isLoggingEnabled)
        #expect(sdk.dependencies != nil)
        #expect(sdk.brandConfiguration?.stageRecaptchaSiteKey == "stage-key")
        #expect(await httpClient.requestCount == 1)

        let request = try #require(await httpClient.requests.first)
        #expect(request.method == .GET)
        #expect(
            request.url
                == dependencies.endpointProvider.url(
                    for: .brandConfig(brandId: "brand-key")
                )
        )
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
        let httpClient = HTTPClientSpy(outcomes: [.success(brandConfigurationData)])
        let coordinator = RootCoordinatorSpy()
        let dependencies = makeDependencies(
            httpClient: httpClient,
            coordinator: coordinator
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
        #expect(input.brandConfiguration != nil)
        #expect(input.splitTextAndAction)
        #expect(input.forSwiftUI)
        #expect(input.placementsConfiguration.popUpStyling != nil)
        #expect((dependencies.httpClientFactory as? HTTPClientFactorySpy)?.makeCount == 2)
        #expect((dependencies.rtpsCoordinatorFactory as? RootCoordinatorFactorySpy)?.makeCount == 1)
        #expect(events.eventCount > 0)
    }

    @Test
    func silentRTPSRequestLazilyFetchesBrandConfiguration() async throws {
        let httpClient = HTTPClientSpy(outcomes: [
            .failure(testError),
            .success(brandConfigurationData),
        ])
        let coordinator = RootCoordinatorSpy()
        let dependencies = makeDependencies(
            httpClient: httpClient,
            coordinator: coordinator
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
        #expect(await httpClient.requestCount == 2)
        #expect(sdk.brandConfiguration?.stageRecaptchaSiteKey == "stage-key")
        let input = try #require(await coordinator.lastInput)
        #expect(input.brandConfiguration?.stageRecaptchaSiteKey == "stage-key")
        let requests = await httpClient.requests
        #expect(
            requests.last?.url
                == dependencies.endpointProvider.url(
                    for: .brandConfig(brandId: "brand-key")
                )
        )
        #expect((dependencies.httpClientFactory as? HTTPClientFactorySpy)?.makeCount == 2)
    }

    private func makeDependencies(
        httpClient: HTTPClientSpy,
        coordinator: RootCoordinatorSpy = RootCoordinatorSpy()
    ) -> SDKDependencies {
        SDKDependencies(
            httpClientFactory: HTTPClientFactorySpy(client: httpClient),
            endpointProvider: LiveAPIEndpointProvider(environment: .stage),
            rtpsCoordinatorFactory: RootCoordinatorFactorySpy(coordinator: coordinator)
        )
    }

    private var brandConfigurationData: Data {
        Data(
            """
            {"config":{"rsk_STAGE_NATIVE_IOS":"stage-key"}}
            """.utf8
        )
    }

    private var testError: NSError {
        NSError(domain: "BreadPartnersSDKTests", code: 1)
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

private final class RootCoordinatorFactorySpy: RTPSCoordinatorFactory, @unchecked Sendable {
    let coordinator: any RealTimePrescreenCoordinating
    private(set) var makeCount = 0

    init(coordinator: any RealTimePrescreenCoordinating) {
        self.coordinator = coordinator
    }

    func makeCoordinator(httpClient: any HTTPClient) -> any RealTimePrescreenCoordinating {
        makeCount += 1
        return coordinator
    }
}

private actor RootCoordinatorSpy: RealTimePrescreenCoordinating {
    private(set) var lastInput: RealTimePrescreenInput?

    func runFlow(_ input: RealTimePrescreenInput) async {
        lastInput = input
        input.logger.debugPrint("root SDK test event")
    }
}
