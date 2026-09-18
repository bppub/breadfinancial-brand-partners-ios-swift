import Foundation
import Testing

@testable import BreadPartnersCore

@Suite struct RTPSOutcomeMatchesTests {
    @Test
    func matchesOutcomesWithoutAssociatedValues() {
        #expect(RTPSOutcomeMatches.skipToPlacements(.skipToPlacements))
        #expect(RTPSOutcomeMatches.noAction(.noAction))
        #expect(
            RTPSOutcomeMatches.missingRequiredFields(.failure(.missingRequiredFields))
        )
    }

    @Test
    func rejectsDifferentOutcomeCases() {
        #expect(RTPSOutcomeMatches.skipToPlacements(.noAction) == false)
        #expect(RTPSOutcomeMatches.noAction(.skipToPlacements) == false)
        #expect(
            RTPSOutcomeMatches.missingRequiredFields(.failure(.api(message: "error"))) == false
        )
    }

    @Test
    func extractsProceedResponse() {
        let response = RTPSFixtures.Response.approved(prescreenId: 42)

        let result = RTPSOutcomeMatches.proceedResponse(.proceedToPlacements(response))

        #expect(result?.prescreenId == 42)
    }

    @Test
    func extractsChallengePayload() {
        let result = RTPSOutcomeMatches.challengePayload(
            .challenge(htmlContent: "<html>", originalURL: "https://challenge.test")
        )

        #expect(result?.htmlContent == "<html>")
        #expect(result?.originalURL == "https://challenge.test")
    }

    @Test
    func extractsApiMessage() {
        let result = RTPSOutcomeMatches.apiMessage(
            .failure(.api(message: "request failed"))
        )

        #expect(result == "request failed")
    }

    @Test
    func extractsUnderlyingError() {
        let error = NSError(domain: "Test", code: 9)

        let result = RTPSOutcomeMatches.underlyingError(.failure(.underlying(error)))

        #expect(result?.domain == "Test")
        #expect(result?.code == 9)
    }
}