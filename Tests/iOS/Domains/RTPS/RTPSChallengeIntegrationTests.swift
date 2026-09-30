import Foundation
import Testing
import WebKit

@testable import BreadPartners

@Suite(.serialized)
@MainActor
struct RTPSChallengeIntegrationTests {
    @Test
    func challengeOutcomeRendersChallengeController() async {
        let httpClient = HTTPClientSpy(outcomes: [
            .failure(RTPSTestFixtures.Error.incapsula)
        ])
        let sdk = makeSDK()
        let events = EventCapture()

        await makeCoordinator(httpClient: httpClient).runFlow(
            makeRequest(sdk: sdk, callback: events.record)
        )

        guard case let .renderPopupView(view) = events.first else {
            Issue.record("Expected the RTPS challenge to render a popup view")
            return
        }

        #expect(view is ChallengeController)
        #expect(await httpClient.requests.count == 1)
    }

    @Test
    func challengeCompletionRetriesRTPSRequestWithCookies() async throws {
        let httpClient = HTTPClientSpy(outcomes: [
            .failure(RTPSTestFixtures.Error.incapsula),
            .success(Data()),
            .success(Data()),
        ])
        let decoder = ResponseDecoderStub(
            responses: [
                .rtps(RTPSTestFixtures.Response.approved),
                .placements(RTPSTestFixtures.Response.emptyPlacements),
            ]
        )
        let sdk = makeSDK()
        let events = EventCapture()

        await makeCoordinator(httpClient: httpClient, decoder: decoder).runFlow(
            makeRequest(sdk: sdk, callback: events.record)
        )

        guard case let .renderPopupView(view) = events.first,
            let challengeController = view as? ChallengeController
        else {
            Issue.record("Expected the RTPS challenge to render a popup view")
            return
        }

        challengeController.loadViewIfNeeded()
        guard let webView = challengeController.view.subviews.compactMap({ $0 as? WKWebView }).first else {
            Issue.record("Expected ChallengeController to contain a WKWebView")
            return
        }

        challengeController.webView(webView, didStartProvisionalNavigation: nil)
        challengeController.webView(webView, didFinish: nil)

        let cookie = try #require(
            HTTPCookie(properties: [
                .domain: "challenge.test",
                .path: "/",
                .name: "incap_ses_test",
                .value: "cookie-value",
            ])
        )
        await webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
        challengeController.cookiesDidChange(in: webView.configuration.websiteDataStore.httpCookieStore)

        try await waitUntil {
            let requestCount = await httpClient.requestCount
            return requestCount >= 3 && events.containsSDKError
        }

        let requests = await httpClient.requests
        #expect(requests.count == 3)
        #expect(requests[1].cookies?.contains("incap_ses_test=cookie-value") == true)
    }

    @Test
    func approvedOutcomeIssuesPlacementRequest() async {
        let httpClient = HTTPClientSpy(outcomes: [
            .success(Data()),
            .success(Data()),
        ])
        let decoder = ResponseDecoderStub(
            responses: [
                .rtps(RTPSTestFixtures.Response.approved),
                .placements(RTPSTestFixtures.Response.emptyPlacements),
            ]
        )
        let sdk = makeSDK()
        let events = EventCapture()

        let coordinator = makeCoordinator(httpClient: httpClient, decoder: decoder)
        await coordinator.runFlow(
            makeRequest(sdk: sdk, callback: events.record)
        )

        let requests = await httpClient.requests
        #expect(requests.count == 2)
        #expect(requests[1].method == .POST)
        #expect(
            requests[1].url == URL(string: "https://brands.kmsmep.com/generatePlacements")
        )
        #expect(events.containsSDKError)
    }

    private func makeSDK() -> BreadPartnersSDK {
        let sdk = BreadPartnersSDK()
        sdk.integrationKey = "integration-key"
        sdk.sdkEnvironment = .stage
        return sdk
    }

    private func makeCoordinator(
        httpClient: HTTPClientSpy,
        decoder: ResponseDecoderStub = ResponseDecoderStub(
            responses: [.rtps(RTPSTestFixtures.Response.neutral)]
        )
    ) -> RTPSCoordinator {
        RTPSCoordinator(
            environment: .stage,
            endpointProvider: LiveAPIEndpointProvider(environment: .stage),
            dependencies: RTPSDependencies(
                recaptcha: RecaptchaStub(),
                httpClient: httpClient,
                requestBuilder: RTPSRequestBuilder(),
                responseDecoder: decoder
            ),
            placementService: LivePlacementService(httpClient: httpClient),
            makeUICoordinator: { RTPSUICoordinator.live }
        )
    }

    private func makeRequest(
        sdk: BreadPartnersSDK,
        merchantConfiguration: MerchantConfiguration = RTPSTestFixtures.MerchantConfigurationFixture.complete,
        placementsConfiguration: PlacementConfiguration = RTPSTestFixtures.PlacementConfigurationFixture.rtps,
        callback: @Sendable @escaping (BreadPartnerEvents) -> Void
    ) -> RealTimePrescreenInput {
        RealTimePrescreenInput(
            merchantConfiguration: merchantConfiguration,
            placementsConfiguration: placementsConfiguration,
            integrationKey: sdk.integrationKey,
            brandConfiguration: sdk.brandConfiguration,
            splitTextAndAction: false,
            openPlacementExperience: false,
            forSwiftUI: false,
            logger: Logger(),
            callback: callback
        )
    }

    private func waitUntil(
        _ condition: @escaping @Sendable () async -> Bool
    ) async throws {
        for _ in 0..<250 {
            if await condition() { return }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        Issue.record("Timed out waiting for the RTPS retry")
    }
}
