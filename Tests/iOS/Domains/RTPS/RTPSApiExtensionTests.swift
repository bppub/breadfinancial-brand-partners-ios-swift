import Foundation
import Testing
import WebKit

@testable import BreadPartners

@Suite(.serialized)
@MainActor
struct RTPSApiExtensionTests {
    @Test
    func challengeOutcomeRendersChallengeController() async {
        let httpClient = HTTPClientSpy(outcomes: [
            .failure(RTPSApiFixtures.Error.incapsula)
        ])
        let sdk = makeSDK(httpClient: httpClient)
        let events = EventCapture()

        await sdk.rtpsCall(
            merchantConfiguration: RTPSApiFixtures.MerchantConfigurationFixture.complete,
            placementsConfiguration: RTPSApiFixtures.PlacementConfigurationFixture.rtps,
            logger: Logger(),
            callback: events.record
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
            .failure(RTPSApiFixtures.Error.incapsula),
            .success(Data()),
            .success(Data()),
        ])
        let decoder = ResponseDecoderStub(
            responses: [
                .rtps(RTPSApiFixtures.Response.approved),
                .placements(RTPSApiFixtures.Response.emptyPlacements),
            ]
        )
        let sdk = makeSDK(httpClient: httpClient, decoder: decoder)
        let events = EventCapture()

        await sdk.rtpsCall(
            merchantConfiguration: RTPSApiFixtures.MerchantConfigurationFixture.complete,
            placementsConfiguration: RTPSApiFixtures.PlacementConfigurationFixture.rtps,
            logger: Logger(),
            callback: events.record
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
            return requestCount == 3
        }

        let requests = await httpClient.requests
        #expect(requests[1].cookies?.contains("incap_ses_test=cookie-value") == true)
        #expect(events.containsSDKError)
    }

    @Test
    func approvedOutcomeIssuesPlacementRequest() async {
        let httpClient = HTTPClientSpy(outcomes: [
            .success(Data()),
            .success(Data()),
        ])
        let decoder = ResponseDecoderStub(
            responses: [
                .rtps(RTPSApiFixtures.Response.approved),
                .placements(RTPSApiFixtures.Response.emptyPlacements),
            ]
        )
        let sdk = makeSDK(httpClient: httpClient, decoder: decoder)
        let events = EventCapture()

        await sdk.rtpsCall(
            merchantConfiguration: RTPSApiFixtures.MerchantConfigurationFixture.complete,
            placementsConfiguration: RTPSApiFixtures.PlacementConfigurationFixture.rtps,
            logger: Logger(),
            callback: events.record
        )

        let requests = await httpClient.requests
        #expect(requests.count == 2)
        #expect(requests[1].method == .POST)
        #expect(
            requests[1].url == sdk.dependencies.endpointProvider.url(for: .generatePlacements)
        )
        #expect(events.containsSDKError)
    }

    private func makeSDK(
        httpClient: HTTPClientSpy,
        decoder: ResponseDecoderStub = ResponseDecoderStub(
            responses: [.rtps(RTPSApiFixtures.Response.neutral)]
        )
    ) -> BreadPartnersSDK {
        let sdk = BreadPartnersSDK()
        sdk.integrationKey = "integration-key"
        sdk.sdkEnvironment = .stage
        sdk.rtpsDependencies = RTPSDependencies(
            recaptcha: RecaptchaStub(),
            httpClient: httpClient,
            requestBuilder: RTPSRequestBuilder(),
            responseDecoder: decoder
        )
        return sdk
    }

    private func waitUntil(
        _ condition: @escaping @Sendable () async -> Bool
    ) async throws {
        for _ in 0..<50 {
            if await condition() { return }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        Issue.record("Timed out waiting for the RTPS retry")
    }
}
