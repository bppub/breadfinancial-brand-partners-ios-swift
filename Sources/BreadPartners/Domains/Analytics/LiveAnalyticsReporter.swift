import Foundation

internal struct LiveAnalyticsReporter: AnalyticsReporting {
    private let service: AnalyticsService
    private let httpClient: any HTTPClient

    init(service: AnalyticsService, httpClient: any HTTPClient) {
        self.service = service
        self.httpClient = httpClient
    }

    func send(event: AnalyticsEvent, placementResponse: PlacementsResponse) async {
        let timestamp = formattedUTCTimestamp(for: Date())
        let userAgent = await DeviceInformationProvider.userAgent
        await service.send(
            event: event, httpClient: httpClient,
            placementResponse: placementResponse, timestamp: timestamp, apiKey: "", userAgent: userAgent
        )
    }
}
