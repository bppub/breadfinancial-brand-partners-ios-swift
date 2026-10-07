import BreadPartnersCore
import BreadPartnersTestSupport
import Foundation
import Testing

@Suite struct AnalyticsReportingServiceTests {
    @Test(arguments: [false, true])
    func sendsExpectedEventToInjectedEndpointWithLegacyMethodHeadersAndPayload(isClick: Bool) async throws {
        let httpClient = HTTPClientSpy(outcomes: [.success(Data("ignored response".utf8))])
        let endpoints = try makeEndpoints()
        let service = AnalyticsReportingService(httpClient: httpClient, endpointProvider: endpoints)
        let response = try JSONDecoder().decode(
            PlacementsResponse.self,
            from: Data(
                #"{"placements":[{"id":"placement","renderContext":{"LOCATION":"product","SDK_TID":"tracking"}}],"placementContent":[{"id":"content","contentType":"text","metadata":{"templateId":"template"}}]}"#
                    .utf8
            )
        )

        if isClick {
            await service.sendClickPlacement(
                placementResponse: response, timestamp: "timestamp", apiKey: "key", userAgent: "device"
            )
        } else {
            await service.sendViewPlacement(
                placementResponse: response, timestamp: "timestamp", apiKey: "key", userAgent: "device"
            )
        }

        let requests = await httpClient.requests
        #expect(requests.count == 1)
        let request = try #require(requests.first)
        #expect(request.url == (isClick ? endpoints.clickURL : endpoints.viewURL))
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
        let name = isClick ? "click-placement" : "view-placement"
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
        arguments: [false, true],
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
    func swallowsFailuresWithoutRetryAndAllowsSubsequentEvents(isClick: Bool, error: NSError) async throws {
        let httpClient = HTTPClientSpy(outcomes: [.failure(error), .success(Data())])
        let endpoints = try makeEndpoints()
        let service = AnalyticsReportingService(httpClient: httpClient, endpointProvider: endpoints)
        let response = PlacementsResponse(placements: nil, placementContent: nil)

        if isClick {
            await service.sendClickPlacement(
                placementResponse: response, timestamp: "first", apiKey: "", userAgent: nil
            )
        } else {
            await service.sendViewPlacement(
                placementResponse: response, timestamp: "first", apiKey: "", userAgent: nil
            )
        }
        #expect(await httpClient.requestCount == 1)

        await service.sendViewPlacement(
            placementResponse: response, timestamp: "second", apiKey: "next-key", userAgent: "next-device"
        )

        let requests = await httpClient.requests
        #expect(requests.count == 2)
        #expect(requests.first?.url == (isClick ? endpoints.clickURL : endpoints.viewURL))
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
        let service = AnalyticsReportingService(httpClient: httpClient, endpointProvider: try makeEndpoints())

        await service.sendClickPlacement(
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
        let service = AnalyticsReportingService(httpClient: httpClient, endpointProvider: try makeEndpoints())

        await service.sendViewPlacement(
            placementResponse: PlacementsResponse(placements: nil, placementContent: nil),
            timestamp: "timestamp", apiKey: "key", userAgent: nil
        )

        #expect(await httpClient.requestCount == 1)
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
