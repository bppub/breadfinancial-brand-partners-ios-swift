import Foundation

package enum PlacementOutcome: Sendable {
    case success(PlacementsResponse)
    case challenge(htmlContent: String, originalURL: String, error: NSError)
    case failure(NSError)
}
