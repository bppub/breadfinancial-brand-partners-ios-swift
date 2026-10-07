import Foundation
import BreadPartnersCore

protocol AnalyticsReporterFactory: Sendable {
    func makeReporter(httpClient: any HTTPClient) -> any AnalyticsReporting
}

final class LiveAnalyticsReporterFactory: AnalyticsReporterFactory {
    private let service: AnalyticsService

    init(endpointProvider: any APIEndpointProviding) {
        self.service = AnalyticsService(endpointProvider: endpointProvider)
    }

    func makeReporter(httpClient: any HTTPClient) -> any AnalyticsReporting {
        LiveAnalyticsReporter(service: service, httpClient: httpClient)
    }
}
