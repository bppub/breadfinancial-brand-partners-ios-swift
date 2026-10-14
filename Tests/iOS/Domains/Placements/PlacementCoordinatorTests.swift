import BreadPartnersCore
import BreadPartnersTestSupport
import Foundation
import Testing

@testable import BreadPartners

@Suite
@MainActor
struct PlacementCoordinatorTests {
    @Test
    func defaultUICoordinatorFactoryForwardsMappedFailure() async throws {
        let error = NSError(
            domain: "Transport",
            code: 401,
            userInfo: [NSLocalizedDescriptionKey: "request failed"]
        )
        let events = EventCapture()
        let coordinator = PlacementCoordinator(
            environment: .stage,
            endpointProvider: PlacementCoordinatorEndpointStub(url: endpoint)
        )

        await coordinator.runFlow(
            makeInput(
                client: HTTPClientSpy(outcomes: [.failure(error)]),
                callback: events.record
            )
        )

        #expect(events.eventCount == 1)
        guard case let .sdkError(actualError) = try #require(events.first) else {
            Issue.record("Expected the live UI coordinator to publish an SDK error")
            return
        }
        #expect((actualError as NSError).code == 500)
        #expect(actualError.localizedDescription == Constants.apiError(message: "request failed"))
    }

    @Test
    func successBuildsRequestAndForwardsResponseAndRenderContext() async throws {
        let client = HTTPClientSpy(outcomes: [.success(Data("{\"placementContent\":[{\"id\":\"offer\"}]}".utf8))])
        let ui = PlacementCoordinatorUISpy()
        let analyticsReporter = PlacementCoordinatorAnalyticsSpy()
        let input = makeInput(client: client, analyticsReporter: analyticsReporter)

        await makeCoordinator(ui: ui).runFlow(input)

        let requests = await client.requests
        let request = try #require(requests.first)
        #expect(requests.count == 1)
        #expect(request.url == endpoint)
        #expect(request.method == .POST)
        #expect(request.cookies == nil)
        let body = try JSONDecoder().decode(PlacementRequest.self, from: #require(request.body))
        #expect(body.brandId == input.integrationKey)
        #expect(body.placements?.first?.context?.ENV == BreadPartnersEnvironment.stage.rawValue)
        #expect(ui.response?.placementContent?.first?.id == "offer")
        #expect(ui.input?.splitTextAndAction == true)
        #expect(ui.input?.openPlacementExperience == true)
        #expect(ui.input?.forSwiftUI == true)
        #expect(ui.input?.logger === input.logger)
        #expect((ui.input?.httpClient as? HTTPClientSpy) === client)
        #expect((ui.input?.analyticsReporter as? PlacementCoordinatorAnalyticsSpy) === analyticsReporter)
        #expect(ui.actions == ["placement"])
    }

    @Test(arguments: ["Transport", NetworkChallengeConstants.domain])
    func failureForwardsOriginalErrorWithoutRendering(domain: String) async throws {
        let error = NSError(domain: domain, code: 401)
        let client = HTTPClientSpy(outcomes: [.failure(error)])
        let ui = PlacementCoordinatorUISpy()

        await makeCoordinator(ui: ui).runFlow(makeInput(client: client))

        #expect(ui.failure === error)
        #expect(ui.actions == ["failure"])
        #expect(await client.requestCount == 1)
    }

    @Test
    func challengeRetriesWithCookieAndOriginalContext() async throws {
        let error = NSError(
            domain: NetworkChallengeConstants.domain,
            code: 401,
            userInfo: [
                NetworkChallengeConstants.htmlContentKey: "challenge html",
                NetworkChallengeConstants.urlKey: "https://challenge.test",
            ]
        )
        let client = HTTPClientSpy(outcomes: [.failure(error), .success(Data("{}".utf8))])
        let ui = PlacementCoordinatorUISpy()
        let analyticsReporter = PlacementCoordinatorAnalyticsSpy()
        let input = makeInput(client: client, analyticsReporter: analyticsReporter)
        let coordinator = makeCoordinator(ui: ui)

        await coordinator.runFlow(input)

        #expect(ui.htmlContent == "challenge html")
        #expect(ui.originalURL == "https://challenge.test")
        #expect(ui.actions == ["challenge"])
        let complete = try #require(ui.onComplete)
        complete("incap_ses=token")
        for await action in ui.actionStream where action == "placement" { break }

        let requests = await client.requests
        #expect(requests.count == 2)
        #expect(requests[0].cookies == nil)
        #expect(requests[1].cookies == "incap_ses=token")
        #expect(requests[1].url == requests[0].url)
        let originalBody = try JSONDecoder().decode(PlacementRequest.self, from: #require(requests[0].body))
        let retryBody = try JSONDecoder().decode(PlacementRequest.self, from: #require(requests[1].body))
        let originalContext = try #require(originalBody.placements?.first?.context)
        let retryContext = try #require(retryBody.placements?.first?.context)
        #expect(retryBody.brandId == originalBody.brandId)
        #expect(retryContext.ENV == originalContext.ENV)
        #expect(retryContext.STORE_NUMBER == originalContext.STORE_NUMBER)
        #expect(retryContext.channel == originalContext.channel)
        #expect(retryContext.subchannel == originalContext.subchannel)
        let originalQuery = URLComponents(string: "https://upq.test/?\(originalContext.UPQ_PARAMS ?? "")")
        let retryQuery = URLComponents(string: "https://upq.test/?\(retryContext.UPQ_PARAMS ?? "")")
        #expect(
            try #require(retryQuery?.queryItems).sorted { $0.name < $1.name }
                == #require(originalQuery?.queryItems).sorted { $0.name < $1.name })
        #expect(ui.input?.integrationKey == input.integrationKey)
        #expect(ui.input?.splitTextAndAction == input.splitTextAndAction)
        #expect(ui.input?.openPlacementExperience == input.openPlacementExperience)
        #expect(ui.input?.forSwiftUI == input.forSwiftUI)
        #expect(ui.input?.logger === input.logger)
        #expect((ui.input?.httpClient as? HTTPClientSpy) === client)
        #expect((ui.input?.analyticsReporter as? PlacementCoordinatorAnalyticsSpy) === analyticsReporter)
        #expect(ui.actions == ["challenge", "placement"])
    }

    private var endpoint: URL { URL(string: "https://placements.test/generate")! }

    private func makeCoordinator(ui: PlacementCoordinatorUISpy) -> PlacementCoordinator {
        let endpoints = PlacementCoordinatorEndpointStub(url: endpoint)
        return PlacementCoordinator(
            environment: .stage,
            endpointProvider: endpoints,
            makeUICoordinator: { ui }
        )
    }

    private func makeInput(
        client: HTTPClientSpy,
        analyticsReporter: any AnalyticsReporting = PlacementCoordinatorAnalyticsSpy(),
        callback: @escaping @Sendable (BreadPartnerEvents) -> Void = { _ in }
    ) -> PlacementCoordinatorInput {
        PlacementCoordinatorInput(
            httpClient: client,
            analyticsReporter: analyticsReporter,
            integrationKey: "brand-key",
            merchantConfiguration: MerchantConfiguration(),
            placementsConfiguration: PlacementConfiguration(),
            splitTextAndAction: true,
            openPlacementExperience: true,
            forSwiftUI: true,
            logger: Logger(),
            callback: callback
        )
    }
}

private actor PlacementCoordinatorAnalyticsSpy: AnalyticsReporting {
    func send(event: AnalyticsEvent, placementResponse: PlacementsResponse) async {}
}

private struct PlacementCoordinatorEndpointStub: APIEndpointProviding {
    let url: URL

    func url(for endpoint: APIEndpoint) -> URL { url }
}

@MainActor
private final class PlacementCoordinatorUISpy: PlacementUICoordinating {
    private(set) var response: PlacementsResponse?
    private(set) var input: PlacementCoordinatorInput?
    private(set) var failure: NSError?
    private(set) var htmlContent: String?
    private(set) var originalURL: String?
    private(set) var onComplete: (@MainActor (String) -> Void)?
    private(set) var actions: [String] = []
    let actionStream: AsyncStream<String>
    private let continuation: AsyncStream<String>.Continuation

    init() {
        (actionStream, continuation) = AsyncStream<String>.makeStream()
    }

    func presentPlacement(
        _ response: PlacementsResponse,
        input: PlacementCoordinatorInput
    ) async {
        self.response = response
        self.input = input
        actions.append("placement")
        continuation.yield("placement")
    }

    func presentChallenge(
        htmlContent: String,
        originalURL: String,
        callback: @escaping @Sendable (BreadPartnerEvents) -> Void,
        logger: Logger,
        onComplete: @escaping @MainActor (String) -> Void
    ) {
        self.htmlContent = htmlContent
        self.originalURL = originalURL
        self.onComplete = onComplete
        actions.append("challenge")
    }

    func presentFailure(_ error: NSError, callback: @escaping @Sendable (BreadPartnerEvents) -> Void) {
        failure = error
        actions.append("failure")
        continuation.yield("failure")
    }
}
