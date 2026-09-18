import Foundation

@testable import BreadPartnersCore

enum RTPSOutcomeMatches {
    static func skipToPlacements(_ outcome: RTPSOutcome) -> Bool {
        if case .skipToPlacements = outcome { return true }
        return false
    }

    static func noAction(_ outcome: RTPSOutcome) -> Bool {
        if case .noAction = outcome { return true }
        return false
    }

    static func missingRequiredFields(_ outcome: RTPSOutcome) -> Bool {
        if case .failure(.missingRequiredFields) = outcome { return true }
        return false
    }

    static func proceedResponse(_ outcome: RTPSOutcome) -> RTPSResponse? {
        if case .proceedToPlacements(let response) = outcome { return response }
        return nil
    }

    static func challengePayload(
        _ outcome: RTPSOutcome
    ) -> (htmlContent: String, originalURL: String)? {
        if case .challenge(let htmlContent, let originalURL) = outcome {
            return (htmlContent, originalURL)
        }
        return nil
    }

    static func apiMessage(_ outcome: RTPSOutcome) -> String? {
        if case .failure(.api(let message)) = outcome { return message }
        return nil
    }

    static func underlyingError(_ outcome: RTPSOutcome) -> NSError? {
        if case .failure(.underlying(let error)) = outcome { return error }
        return nil
    }
}
