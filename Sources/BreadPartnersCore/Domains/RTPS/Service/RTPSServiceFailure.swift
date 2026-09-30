import Foundation

/// Typed failures returned by `RTPSService` so Core does not depend on SDK error strings or events.
package enum RTPSServiceFailure: Sendable {
    case missingRequiredFields
    case api(message: String)
    case underlying(NSError)
}
