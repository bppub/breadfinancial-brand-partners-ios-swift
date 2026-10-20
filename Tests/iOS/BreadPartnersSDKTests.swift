//------------------------------------------------------------------------------
//  File:          BreadPartnersSDKTests.swift
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
import BreadPartnersCore
import UIKit

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
        let httpClient = HTTPClientSpy(outcomes: [
            .success(try JSONEncoder().encode(makeTextPlacementResponse())),
            .success(Data()),
        ])
        let (reported, reportedContinuation) = AsyncStream<Void>.makeStream()
        let observedClient = AnalyticsHTTPClientObserver(client: httpClient, reported: reportedContinuation)
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
        await sdk.registerPlacements(
            merchantConfiguration: MerchantConfiguration(),
            placementsConfiguration: PlacementConfiguration(), callback: events.record
        )

        for await _ in reported { break }
        let requests = await httpClient.requests
        try #require(requests.count == 2)
        #expect(requests[0].method == .POST)
        #expect(requests[0].url == dependencies.endpointProvider.url(for: .generatePlacements))
        #expect(requests[1].url == endpoint)
        #expect(requests[1].method == .OPTIONS)
        let payload = try JSONDecoder().decode(Analytics.Payload.self, from: #require(requests[1].body))
        #expect(payload.name == "view-placement")
        #expect(payload.context?.apiKey == "")
        #expect((dependencies.httpClientFactory as? HTTPClientFactorySpy)?.makeCount == 2)
        #expect((dependencies.httpClientFactory as? HTTPClientFactorySpy)?.lastLogger?.isLoggingEnabled == false)
        #expect(events.eventCount == 1)
        guard case .renderTextViewWithLink = try #require(events.first) else {
            Issue.record("Expected the original text render callback")
            return
        }
    }

    @Test
    func registerPlacementsUsesInjectedHTTPClientAndPreservesRenderFlags() async throws {
        let response = makeTextPlacementResponse()
        let httpClient = HTTPClientSpy(outcomes: [
            .success(try JSONEncoder().encode(response)),
            .success(Data()),
        ])
        let endpoint = try #require(URL(string: "https://placements.test/generate"))
        let sdk = BreadPartnersSDK()
        let dependencies = makeDependencies(
            httpClient: httpClient,
            brandConfigurationService: BrandConfigurationServiceSpy(results: [brandConfiguration]),
            endpointProvider: FixedPlacementEndpointProvider(url: endpoint)
        )
        let events = EventCapture()

        await sdk.setup(
            environment: .stage,
            integrationKey: "brand-key",
            enableLog: false,
            dependencies: dependencies
        )
        await sdk.registerPlacements(
            merchantConfiguration: MerchantConfiguration(),
            placementsConfiguration: PlacementConfiguration(),
            splitTextAndAction: true,
            forSwiftUI: true,
            callback: events.record
        )

        let requests = await httpClient.requests.filter { $0.method == .POST }
        let request = try #require(requests.first)
        #expect(requests.count == 1)
        #expect(request.url == endpoint)
        #expect(request.cookies == nil)
        let body = try JSONDecoder().decode(PlacementRequest.self, from: #require(request.body))
        #expect(body.brandId == "brand-key")
        #expect(body.placements?.first?.context?.ENV == BreadPartnersEnvironment.stage.rawValue)
        guard case .renderSwiftUISeparateTextAndButton = try #require(events.first) else {
            Issue.record("Expected the SwiftUI split text/action callback")
            return
        }
    }

    @Test
    func openExperienceSelectsOverlayAndUsesDefaultStyling() async throws {
        let response = PlacementsResponse(
            placements: nil,
            placementContent: [
                PlacementContentModel(
                    id: "text",
                    contentType: nil,
                    contentData: ContentDataModel(htmlContent: "ignored"),
                    metadata: MetadataModel(placementId: nil, productType: nil, messageId: nil, templateId: "text")
                ),
                PlacementContentModel(
                    id: "overlay",
                    contentType: nil,
                    contentData: ContentDataModel(
                        htmlContent:
                            "<div data-overlay-metadata data-overlay-type=\"EMBEDDED_OVERLAY\"></div><iframe src=\"about:blank\"></iframe>"
                    ),
                    metadata: MetadataModel(
                        placementId: nil,
                        productType: nil,
                        messageId: nil,
                        templateId: "approval-overlay"
                    )
                ),
            ]
        )
        let httpClient = HTTPClientSpy(outcomes: [
            .success(try JSONEncoder().encode(response)),
            .success(Data()),
        ])
        let sdk = BreadPartnersSDK()
        await sdk.setup(
            environment: .stage,
            integrationKey: "brand-key",
            enableLog: false,
            dependencies: makeDependencies(
                httpClient: httpClient,
                brandConfigurationService: BrandConfigurationServiceSpy(results: [brandConfiguration])
            )
        )
        let events = EventCapture()

        await sdk.openExperienceForPlacement(
            merchantConfiguration: MerchantConfiguration(),
            placementsConfiguration: PlacementConfiguration(),
            callback: events.record
        )

        #expect(await httpClient.requests.filter { $0.method == .POST }.count == 1)
        try #require(events.events.count == 2)
        guard case .textClicked = events.events[0],
            case let .renderPopupView(view) = events.events[1]
        else {
            Issue.record("Expected the overlay click and popup callbacks in order")
            return
        }
        let popup = try #require(view as? PopupController)
        #expect(popup.popupModel.overlayType == PlacementOverlayType.embeddedOverlay.rawValue)
        #expect(popup.placementsConfiguration?.popUpStyling != nil)
    }

    @Test
    func placementChallengeCompletionRetriesWithCookieAndOriginalFlags() async throws {
        let challengeError = NSError(
            domain: NetworkChallengeConstants.domain,
            code: 401,
            userInfo: [
                NetworkChallengeConstants.htmlContentKey: "challenge html",
                NetworkChallengeConstants.urlKey: "https://challenge.test",
            ]
        )
        let httpClient = HTTPClientSpy(outcomes: [
            .failure(challengeError),
            .success(try JSONEncoder().encode(makeTextPlacementResponse())),
            .success(Data()),
        ])
        let challengeFactory = PlacementChallengeFactorySpy()
        let sdk = BreadPartnersSDK()
        let dependencies = makeDependencies(
            httpClient: httpClient,
            brandConfigurationService: BrandConfigurationServiceSpy(results: [brandConfiguration]),
            placementUICoordinator: PlacementUICoordinator(challengeFactory: challengeFactory)
        )
        await sdk.setup(
            environment: .stage,
            integrationKey: "brand-key",
            enableLog: false,
            dependencies: dependencies
        )
        let events = EventCapture()
        let (renderStream, renderContinuation) = AsyncStream<Bool>.makeStream()
        let callback: @Sendable (BreadPartnerEvents) -> Void = { event in
            events.record(event)
            if case .renderSwiftUISeparateTextAndButton = event {
                renderContinuation.yield(true)
            }
        }

        await sdk.registerPlacements(
            merchantConfiguration: MerchantConfiguration(),
            placementsConfiguration: PlacementConfiguration(),
            splitTextAndAction: true,
            forSwiftUI: true,
            callback: callback
        )

        #expect(challengeFactory.htmlContent == "challenge html")
        #expect(challengeFactory.originalURL == "https://challenge.test")
        guard case .renderPopupView = try #require(events.first) else {
            Issue.record("Expected the challenge controller callback")
            return
        }
        let onComplete = try #require(challengeFactory.onComplete)
        onComplete("incap_ses=token")
        for await didRender in renderStream where didRender { break }

        let requests = await httpClient.requests.filter { $0.method == .POST }
        try #require(requests.count == 2)
        #expect(requests[0].cookies == nil)
        #expect(requests[1].cookies == "incap_ses=token")
        let body = try JSONDecoder().decode(PlacementRequest.self, from: #require(requests[1].body))
        #expect(body.placements?.first?.context?.ENV == BreadPartnersEnvironment.stage.rawValue)
        guard case .renderSwiftUISeparateTextAndButton = events.events.last else {
            Issue.record("Expected the original render flags after the challenge retry")
            return
        }
    }

    @Test
    func placementAPIsForwardToInjectedCoordinatorWithDefaultsAndOriginalFlags() async throws {
        let coordinator = RootPlacementCoordinatorSpy()
        let client = HTTPClientSpy()
        let sdk = BreadPartnersSDK()
        let events = EventCapture()
        await sdk.setup(
            environment: .stage,
            integrationKey: "brand-key",
            enableLog: true,
            dependencies: makeDependencies(
                httpClient: client,
                brandConfigurationService: BrandConfigurationServiceSpy(results: [brandConfiguration]),
                placementCoordinator: coordinator
            )
        )

        await sdk.registerPlacements(
            merchantConfiguration: MerchantConfiguration(),
            placementsConfiguration: PlacementConfiguration(),
            splitTextAndAction: true,
            forSwiftUI: true,
            callback: events.record
        )
        await sdk.openExperienceForPlacement(
            merchantConfiguration: MerchantConfiguration(),
            placementsConfiguration: PlacementConfiguration(),
            forSwiftUI: true,
            callback: events.record
        )

        let inputs = await coordinator.inputs
        try #require(inputs.count == 2)
        #expect(inputs[0].integrationKey == "brand-key")
        #expect(inputs[0].placementsConfiguration.popUpStyling != nil)
        #expect(inputs[0].splitTextAndAction)
        #expect(inputs[0].forSwiftUI)
        #expect(!inputs[0].openPlacementExperience)
        #expect(inputs[1].placementsConfiguration.popUpStyling != nil)
        #expect(!inputs[1].splitTextAndAction)
        #expect(!inputs[1].forSwiftUI)
        #expect(inputs[1].openPlacementExperience)
        #expect(inputs.allSatisfy { $0.logger.isLoggingEnabled })
        #expect(events.messages.count == 2)
        #expect(await client.requestCount == 0)
    }

    private func makeDependencies(
        httpClient: any HTTPClient,
        coordinator: RootCoordinatorSpy = RootCoordinatorSpy(),
        brandConfigurationService serviceSpy: BrandConfigurationServiceSpy? = nil,
        endpointProvider: any APIEndpointProviding = LiveAPIEndpointProvider(environment: .stage),
        placementUICoordinator: any PlacementUICoordinating = PlacementUICoordinator.live,
        analyticsFactory: (any AnalyticsReporterFactory)? = nil,
        placementCoordinator: (any PlacementCoordinating)? = nil
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

        let httpClientFactory = HTTPClientFactorySpy(client: httpClient)
        let reporterFactory = analyticsFactory ?? LiveAnalyticsReporterFactory(endpointProvider: endpointProvider)

        return SDKDependencies(
            environment: .stage,
            httpClientFactory: httpClientFactory,
            endpointProvider: endpointProvider,
            brandConfigurationService: brandConfigurationService,
            analyticsFactory: reporterFactory,
            placementCoordinator: placementCoordinator
                ?? PlacementCoordinator(
                    environment: .stage,
                    endpointProvider: endpointProvider,
                    makeUICoordinator: { placementUICoordinator }
                ),
            rtpsCoordinator: coordinator
        )
    }

    private func makeTextPlacementResponse() -> PlacementsResponse {
        PlacementsResponse(
            placements: nil,
            placementContent: [
                PlacementContentModel(
                    id: "text",
                    contentType: nil,
                    contentData: ContentDataModel(
                        htmlContent:
                            "<div class=\"ep-text-placement\"><div class=\"epjs-body\">Offer <span class=\"epjs-body-action\"><a>Apply</a></span></div></div>"
                    ),
                    metadata: MetadataModel(placementId: nil, productType: nil, messageId: nil, templateId: "text")
                )
            ]
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
    let reported: AsyncStream<Void>.Continuation

    func request(_ request: HTTPRequest) async throws -> Data {
        defer {
            if request.method == .OPTIONS { reported.yield() }
        }
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

private struct FixedPlacementEndpointProvider: APIEndpointProviding {
    let url: URL

    func url(for endpoint: APIEndpoint) -> URL { url }
}

@MainActor
private final class PlacementChallengeFactorySpy: ChallengeControllerFactory {
    private(set) var htmlContent: String?
    private(set) var originalURL: String?
    private(set) var onComplete: ((String) -> Void)?

    func makeChallengeController(
        htmlContent: String,
        originalURL: String,
        callback: @escaping (BreadPartnerEvents) -> Void,
        onComplete: @escaping (String) -> Void,
        logger: Logger
    ) -> UIViewController {
        self.htmlContent = htmlContent
        self.originalURL = originalURL
        self.onComplete = onComplete
        return UIViewController()
    }
}

private actor RootPlacementCoordinatorSpy: PlacementCoordinating {
    private(set) var inputs: [PlacementCoordinatorInput] = []

    func runFlow(_ input: PlacementCoordinatorInput) async {
        inputs.append(input)
        input.logger.debugPrint("placement coordinator test event")
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
