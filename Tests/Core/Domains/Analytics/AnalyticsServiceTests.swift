import BreadPartnersCore
import BreadPartnersTestSupport
import Foundation
import Testing

@Suite struct AnalyticsServiceTests {
    @Test(arguments: AnalyticsEvent.allCases)
    func sendsExpectedEventToInjectedEndpointWithLegacyMethodHeadersAndPayload(event: AnalyticsEvent) async throws {
        let httpClient = HTTPClientSpy(outcomes: [.success(Data("ignored response".utf8))])
        let endpoints = try makeEndpoints()
        let service = AnalyticsService(endpointProvider: endpoints)
        let response = try JSONDecoder().decode(
            PlacementsResponse.self,
            from: Data(
                #"{"placements":[{"id":"placement","renderContext":{"LOCATION":"product","SDK_TID":"tracking"}}],"placementContent":[{"id":"content","contentType":"text","metadata":{"templateId":"template"}}]}"#
                    .utf8
            )
        )

        await service.send(
            event: event, httpClient: httpClient,
            placementResponse: response, timestamp: "timestamp", apiKey: "key", userAgent: "device"
        )

        let requests = await httpClient.requests
        #expect(requests.count == 1)
        let request = try #require(requests.first)
        #expect(request.url == (event == .clickPlacement ? endpoints.clickURL : endpoints.viewURL))
        #expect(request.method == .OPTIONS)
        #expect(request.cookies == nil)
        #expect(
            request.headers == [
                "authority": "metrics.kmsmep.com",
                "Accept": "*/*",
                "Accept-Encoding": "gzip, deflate, br, zstd",
                "Accept-Language": "en-GB,en-US;q=0.9,en;q=0.8",
                "Access-Control-Request-Headers": "content-type",
                "Access-Control-Request-Method": "POST",
            ])
        let body = try #require(request.body)
        let payload = try JSONDecoder().decode(Analytics.Payload.self, from: body)
        let name = event == .clickPlacement ? "click-placement" : "view-placement"
        #expect(payload.name == name)
        #expect(payload.context?.timestamp == "timestamp")
        #expect(payload.context?.apiKey == "key")
        #expect(payload.context?.browserCtx?.userAgent == "device")
        let expected = AnalyticsPayloadBuilder().build(
            name: name, placementResponse: response, timestamp: "timestamp", apiKey: "key", userAgent: "device"
        )
        #expect(
            try JSONSerialization.jsonObject(with: body) as? NSDictionary
                == JSONSerialization.jsonObject(with: JSONEncoder().encode(expected)) as? NSDictionary
        )
    }

    @Test(
        arguments: AnalyticsEvent.allCases,
        [
            NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet),
            NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled),
            CancellationError() as NSError,
            NSError(domain: "analytics-test", code: 500, userInfo: [NSLocalizedDescriptionKey: "failed"]),
            NSError(
                domain: NetworkChallengeConstants.domain, code: 403,
                userInfo: [
                    NetworkChallengeConstants.htmlContentKey: "<html>challenge</html>",
                    NetworkChallengeConstants.urlKey: "https://challenge.test",
                ]
            ),
        ])
    func swallowsFailuresWithoutRetryAndAllowsSubsequentEvents(event: AnalyticsEvent, error: NSError) async throws {
        let httpClient = HTTPClientSpy(outcomes: [.failure(error), .success(Data())])
        let endpoints = try makeEndpoints()
        let service = AnalyticsService(endpointProvider: endpoints)
        let response = PlacementsResponse(placements: nil, placementContent: nil)

        await service.send(
            event: event, httpClient: httpClient,
            placementResponse: response, timestamp: "first", apiKey: "", userAgent: nil
        )
        #expect(await httpClient.requestCount == 1)

        await service.send(
            event: .viewPlacement, httpClient: httpClient,
            placementResponse: response, timestamp: "second", apiKey: "next-key", userAgent: "next-device"
        )

        let requests = await httpClient.requests
        #expect(requests.count == 2)
        #expect(requests.first?.url == (event == .clickPlacement ? endpoints.clickURL : endpoints.viewURL))
        #expect(requests.last?.url == endpoints.viewURL)
        let payload = try JSONDecoder().decode(Analytics.Payload.self, from: #require(requests.last?.body))
        #expect(payload.name == "view-placement")
        #expect(payload.context?.timestamp == "second")
        #expect(payload.context?.apiKey == "next-key")
        #expect(payload.context?.browserCtx?.userAgent == "next-device")
    }

    @Test
    func swallowsNonNSErrorTransportFailure() async throws {
        let httpClient = HTTPClientSpy()
        let service = AnalyticsService(endpointProvider: try makeEndpoints())

        await service.send(
            event: .clickPlacement, httpClient: httpClient,
            placementResponse: PlacementsResponse(placements: [], placementContent: []),
            timestamp: "", apiKey: "", userAgent: nil
        )

        #expect(await httpClient.requestCount == 1)
        let requests = await httpClient.requests
        let payload = try JSONDecoder().decode(Analytics.Payload.self, from: #require(requests.first?.body))
        #expect(payload.name == "click-placement")
        #expect(payload.context?.timestamp == "")
        #expect(payload.context?.browserCtx?.userAgent == nil)
    }

    @Test(arguments: ["", "not JSON", "[]", "null", #"{"error":"ignored"}"#])
    func ignoresResponseDataWithoutDecodingOrAdditionalRequests(responseBody: String) async throws {
        let httpClient = HTTPClientSpy(outcomes: [.success(Data(responseBody.utf8))])
        let service = AnalyticsService(endpointProvider: try makeEndpoints())

        await service.send(
            event: .viewPlacement, httpClient: httpClient,
            placementResponse: PlacementsResponse(placements: nil, placementContent: nil),
            timestamp: "timestamp", apiKey: "key", userAgent: nil
        )

        #expect(await httpClient.requestCount == 1)
    }

    @Test
    func sharedServiceUsesTheHTTPClientSuppliedForEachOperation() async throws {
        let viewClient = HTTPClientSpy(outcomes: [.success(Data())])
        let clickClient = HTTPClientSpy(outcomes: [.success(Data())])
        let endpoints = try makeEndpoints()
        let service = AnalyticsService(endpointProvider: endpoints)
        let response = PlacementsResponse(placements: nil, placementContent: nil)

        await service.send(
            event: .viewPlacement,
            httpClient: viewClient, placementResponse: response, timestamp: "view", apiKey: "", userAgent: nil
        )
        await service.send(
            event: .clickPlacement,
            httpClient: clickClient, placementResponse: response, timestamp: "click", apiKey: "", userAgent: nil
        )

        let viewRequests = await viewClient.requests
        let clickRequests = await clickClient.requests
        #expect(viewRequests.count == 1)
        #expect(clickRequests.count == 1)
        #expect(viewRequests.first?.url == endpoints.viewURL)
        #expect(clickRequests.first?.url == endpoints.clickURL)
        let viewPayload = try JSONDecoder().decode(Analytics.Payload.self, from: #require(viewRequests.first?.body))
        let clickPayload = try JSONDecoder().decode(Analytics.Payload.self, from: #require(clickRequests.first?.body))
        #expect(viewPayload.name == "view-placement")
        #expect(clickPayload.name == "click-placement")
    }

    @Test
    func eventNamesKeepExactWireValuesAndRejectUnknownEvents() {
        #expect(Set(AnalyticsEvent.allCases.map(\.rawValue)) == ["view-placement", "click-placement"])
        #expect(AnalyticsEvent(rawValue: "view-placement") == .viewPlacement)
        #expect(AnalyticsEvent(rawValue: "click-placement") == .clickPlacement)
        #expect(AnalyticsEvent(rawValue: "unknown") == nil)
    }

    private func makeEndpoints() throws -> AnalyticsEndpointProviderStub {
        AnalyticsEndpointProviderStub(
            viewURL: try #require(URL(string: "https://analytics.test/custom-view")),
            clickURL: try #require(URL(string: "https://analytics.test/custom-click"))
        )
    }
}

private struct AnalyticsEndpointProviderStub: APIEndpointProviding {
    let viewURL: URL
    let clickURL: URL

    func url(for endpoint: APIEndpoint) -> URL {
        switch endpoint {
        case .viewPlacement: viewURL
        case .clickPlacement: clickURL
        default: viewURL.appendingPathComponent("unexpected")
        }
    }
}
