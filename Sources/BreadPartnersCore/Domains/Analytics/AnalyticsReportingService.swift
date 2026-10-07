import Foundation

package struct AnalyticsReportingService: Sendable {
    private let httpClient: any HTTPClient
    private let endpointProvider: any APIEndpointProviding

    package init(httpClient: any HTTPClient, endpointProvider: any APIEndpointProviding) {
        self.httpClient = httpClient
        self.endpointProvider = endpointProvider
    }

    package func sendViewPlacement(
        placementResponse: PlacementsResponse,
        timestamp: String,
        apiKey: String,
        userAgent: String?
    ) async {
        await sendPlacementAnalytics(
            name: "view-placement", endpoint: .viewPlacement,
            placementResponse: placementResponse, timestamp: timestamp, apiKey: apiKey, userAgent: userAgent
        )
    }

    package func sendClickPlacement(
        placementResponse: PlacementsResponse,
        timestamp: String,
        apiKey: String,
        userAgent: String?
    ) async {
        await sendPlacementAnalytics(
            name: "click-placement", endpoint: .clickPlacement,
            placementResponse: placementResponse, timestamp: timestamp, apiKey: apiKey, userAgent: userAgent
        )
    }

    private func sendPlacementAnalytics(
        name: String,
        endpoint: APIEndpoint,
        placementResponse: PlacementsResponse,
        timestamp: String,
        apiKey: String,
        userAgent: String?
    ) async {
        let payload = AnalyticsPayloadBuilder().build(
            name: name, placementResponse: placementResponse, timestamp: timestamp, apiKey: apiKey, userAgent: userAgent
        )

        do {
            _ = try await httpClient.request(
                HTTPRequest(
                    url: endpointProvider.url(for: endpoint),
                    method: .OPTIONS,
                    headers: [
                        "authority": "metrics.kmsmep.com",
                        "Accept": "*/*",
                        "Accept-Encoding": "gzip, deflate, br, zstd",
                        "Accept-Language": "en-GB,en-US;q=0.9,en;q=0.8",
                        "Access-Control-Request-Headers": "content-type",
                        "Access-Control-Request-Method": "POST",
                    ],
                    body: try JSONEncoder().encode(payload)
                )
            )
        } catch {
        }
    }
}
