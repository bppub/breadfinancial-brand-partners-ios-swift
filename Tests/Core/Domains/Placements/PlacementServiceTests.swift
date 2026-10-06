import BreadPartnersTestSupport
import Foundation
import Testing

@testable import BreadPartnersCore

@Suite
struct PlacementServiceTests {
    @Test
    func executePostsEncodedRequestAndDecodesNestedContent() async throws {
        let json = """
            {
                "placements": [{
                    "id": "placement",
                    "content": {"contentId": "content"},
                    "renderContext": {"ENV": "UAT", "RTPS_ID": "123"}
                }],
                "placementContent": [{
                    "id": "content",
                    "contentType": "HTML",
                    "contentData": {"htmlContent": "<p>Offer</p>"},
                    "metadata": {"templateId": "overlay"}
                }]
            }
            """
        let httpClient = HTTPClientSpy(outcomes: [.success(Data(json.utf8))])
        let url = try #require(URL(string: "https://placements.test/generate"))
        let request = PlacementRequest(
            placements: [
                PlacementRequestBody(
                    id: "placement",
                    context: ContextRequestBody(ENV: "UAT", RTPS_ID: "123", ALLOW_CHECKOUT: true)
                )
            ],
            brandId: "integration-key"
        )

        let outcome = await PlacementService().execute(
            PlacementServiceInput(httpClient: httpClient, request: request, url: url)
        )

        guard case let .success(response) = outcome else {
            Issue.record("Expected decoded placement response")
            return
        }
        #expect(response.placements?.first?.id == "placement")
        #expect(response.placements?.first?.content?.contentId == "content")
        #expect(response.placements?.first?.renderContext?.ENV == "UAT")
        #expect(response.placements?.first?.renderContext?.RTPS_ID == "123")
        #expect(response.placementContent?.first?.id == "content")
        #expect(response.placementContent?.first?.contentType == "HTML")
        #expect(response.placementContent?.first?.contentData?.htmlContent == "<p>Offer</p>")
        #expect(response.placementContent?.first?.metadata?.templateId == "overlay")

        let requests = await httpClient.requests
        #expect(requests.count == 1)
        let sentRequest = try #require(requests.first)
        #expect(sentRequest.url == url)
        #expect(sentRequest.method == .POST)
        #expect(sentRequest.headers.isEmpty)
        #expect(sentRequest.cookies == nil)
        let body = try #require(sentRequest.body)
        let expectedBody = try JSONEncoder().encode(request)
        let actualJSON = try JSONSerialization.jsonObject(with: body) as? NSDictionary
        let expectedJSON = try JSONSerialization.jsonObject(with: expectedBody) as? NSDictionary
        #expect(actualJSON == expectedJSON)
    }

    @Test(arguments: [nil, "", "incap_ses=retry; session=value"] as [String?])
    func executeForwardsCookiesUnchanged(cookies: String?) async throws {
        let httpClient = HTTPClientSpy(outcomes: [.success(Data("{}".utf8))])

        _ = await PlacementService().execute(try makeInput(httpClient: httpClient, cookies: cookies))

        let requests = await httpClient.requests
        #expect(requests.count == 1)
        #expect(requests.first?.cookies == cookies)
    }

    @Test(arguments: ["{}", #"{"placements":[],"placementContent":[]}"#])
    func executePreservesMissingAndEmptyContent(json: String) async throws {
        let httpClient = HTTPClientSpy(outcomes: [.success(Data(json.utf8))])

        let outcome = await PlacementService().execute(try makeInput(httpClient: httpClient))

        guard case let .success(response) = outcome else {
            Issue.record("Expected success without content validation")
            return
        }
        if json == "{}" {
            #expect(response.placements == nil)
            #expect(response.placementContent == nil)
        } else {
            #expect(response.placements?.isEmpty == true)
            #expect(response.placementContent?.isEmpty == true)
        }
    }

    @Test(arguments: [
        "not JSON",
        #"{"placements":"invalid"}"#,
        #"{"placementContent":[{"contentData":{"htmlContent":42}}]}"#,
    ])
    func executeReturnsDecodingFailure(json: String) async throws {
        let data = Data(json.utf8)
        let httpClient = HTTPClientSpy(outcomes: [.success(data)])

        let outcome = await PlacementService().execute(try makeInput(httpClient: httpClient))

        guard case let .failure(error) = outcome else {
            Issue.record("Expected decoding failure")
            return
        }
        do {
            _ = try JSONDecoder().decode(PlacementsResponse.self, from: data)
            Issue.record("Expected invalid fixture to fail decoding")
        } catch let expectedError as NSError {
            #expect(error.domain == expectedError.domain)
            #expect(error.code == expectedError.code)
            #expect(error.localizedDescription == expectedError.localizedDescription)
        }
        #expect(await httpClient.requestCount == 1)
    }

    @Test(arguments: ["HTTPError", "InvalidResponse", "InvalidContentType", NSURLErrorDomain])
    func executePreservesHTTPFailure(domain: String) async throws {
        let expectedError = NSError(
            domain: domain,
            code: 503,
            userInfo: [
                NSLocalizedDescriptionKey: "original failure",
                "responseBody": "original response",
                NetworkChallengeConstants.htmlContentKey: "not a challenge",
                NetworkChallengeConstants.urlKey: "https://other.test",
            ]
        )
        let httpClient = HTTPClientSpy(outcomes: [.failure(expectedError)])

        let outcome = await PlacementService().execute(try makeInput(httpClient: httpClient))

        guard case let .failure(error) = outcome else {
            Issue.record("Expected original HTTP failure")
            return
        }
        #expect(error === expectedError)
        #expect(await httpClient.requestCount == 1)
    }

    @Test
    func executeReturnsChallengeMetadataWithoutRetrying() async throws {
        let htmlContent = "<html>_Incapsula_Resource</html>"
        let originalURL = "https://challenge.test/original"
        let httpClient = HTTPClientSpy(
            outcomes: [
                .failure(
                    NSError(
                        domain: NetworkChallengeConstants.domain,
                        code: 403,
                        userInfo: [
                            NetworkChallengeConstants.htmlContentKey: htmlContent,
                            NetworkChallengeConstants.urlKey: originalURL,
                        ]
                    )
                )
            ]
        )

        let outcome = await PlacementService().execute(try makeInput(httpClient: httpClient))

        guard case let .challenge(actualHTML, actualURL) = outcome else {
            Issue.record("Expected security challenge")
            return
        }
        #expect(actualHTML == htmlContent)
        #expect(actualURL == originalURL)
        #expect(await httpClient.requestCount == 1)
    }

    @Test(arguments: [0, 1, 2, 3, 4])
    func executePreservesIncompleteOrInvalidChallengeMetadata(variant: Int) async throws {
        let metadata: [[String: Any]] = [
            [:],
            [NetworkChallengeConstants.htmlContentKey: "challenge"],
            [NetworkChallengeConstants.urlKey: "https://challenge.test"],
            [NetworkChallengeConstants.htmlContentKey: 42, NetworkChallengeConstants.urlKey: "url"],
            [NetworkChallengeConstants.htmlContentKey: "challenge", NetworkChallengeConstants.urlKey: 42],
        ]
        let expectedError = NSError(
            domain: NetworkChallengeConstants.domain,
            code: 403,
            userInfo: metadata[variant]
        )
        let httpClient = HTTPClientSpy(outcomes: [.failure(expectedError)])

        let outcome = await PlacementService().execute(try makeInput(httpClient: httpClient))

        guard case let .failure(error) = outcome else {
            Issue.record("Expected original challenge error")
            return
        }
        #expect(error === expectedError)
        #expect(await httpClient.requestCount == 1)
    }

    private func makeInput(
        httpClient: any HTTPClient,
        cookies: String? = nil
    ) throws -> PlacementServiceInput {
        PlacementServiceInput(
            httpClient: httpClient,
            request: PlacementRequest(),
            url: try #require(URL(string: "https://placements.test/generate")),
            cookies: cookies
        )
    }
}
