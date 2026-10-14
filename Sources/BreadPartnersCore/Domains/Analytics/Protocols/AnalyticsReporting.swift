import Foundation

package protocol AnalyticsReporting: Sendable {
    func send(event: AnalyticsEvent, placementResponse: PlacementsResponse) async
}
