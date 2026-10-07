import XCTest

@testable import BreadPartners

actor AnalyticsReporterSpy: AnalyticsReporting {
    struct Call: Sendable {
        let event: AnalyticsEvent
        let placementResponse: PlacementsResponse
    }

    private(set) var calls: [Call] = []
    private let reported: XCTestExpectation?

    init(reported: XCTestExpectation? = nil) {
        self.reported = reported
    }

    func send(event: AnalyticsEvent, placementResponse: PlacementsResponse) async {
        calls.append(Call(event: event, placementResponse: placementResponse))
        reported?.fulfill()
    }
}
