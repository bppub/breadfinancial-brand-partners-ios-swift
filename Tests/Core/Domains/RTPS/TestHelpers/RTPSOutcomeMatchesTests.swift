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
        #expect(
            RTPSOutcomeMatches.missingRequiredFields(
                .failure(.underlying(NSError(domain: "Test", code: 1)))
            ) == false
        )
    }

    @Test
    func extractsProceedResponse() {
        let response = RTPSFixtures.Response.approved(prescreenId: 42)

        let result = RTPSOutcomeMatches.proceedResponse(.proceedToPlacements(response))

        #expect(result?.prescreenId == 42)
    }

    @Test
    func rejectsNonProceedOutcomes() {
        #expect(RTPSOutcomeMatches.proceedResponse(.skipToPlacements) == nil)
        #expect(RTPSOutcomeMatches.proceedResponse(.noAction) == nil)
        #expect(
            RTPSOutcomeMatches.proceedResponse(
                .challenge(htmlContent: "<html>", originalURL: "https://challenge.test")
            ) == nil
        )
        #expect(RTPSOutcomeMatches.proceedResponse(.failure(.missingRequiredFields)) == nil)
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
    func rejectsNonChallengeOutcomes() {
        #expect(RTPSOutcomeMatches.challengePayload(.skipToPlacements) == nil)
        #expect(RTPSOutcomeMatches.challengePayload(.noAction) == nil)
        #expect(
            RTPSOutcomeMatches.challengePayload(
                .proceedToPlacements(RTPSFixtures.Response.approved(prescreenId: 42))
            ) == nil
        )
        #expect(RTPSOutcomeMatches.challengePayload(.failure(.missingRequiredFields)) == nil)
    }

    @Test
    func extractsApiMessage() {
        let result = RTPSOutcomeMatches.apiMessage(
            .failure(.api(message: "request failed"))
        )

        #expect(result == "request failed")
    }

    @Test
    func rejectsNonApiFailures() {
        #expect(RTPSOutcomeMatches.apiMessage(.skipToPlacements) == nil)
        #expect(RTPSOutcomeMatches.apiMessage(.noAction) == nil)
        #expect(
            RTPSOutcomeMatches.apiMessage(.failure(.missingRequiredFields)) == nil
        )
        #expect(
            RTPSOutcomeMatches.apiMessage(
                .failure(.underlying(NSError(domain: "Test", code: 1)))
            ) == nil
        )
    }

    @Test
    func extractsUnderlyingError() {
        let error = NSError(domain: "Test", code: 9)

        let result = RTPSOutcomeMatches.underlyingError(.failure(.underlying(error)))

        #expect(result?.domain == "Test")
        #expect(result?.code == 9)
    }

    @Test
    func rejectsNonUnderlyingFailures() {
        #expect(RTPSOutcomeMatches.underlyingError(.skipToPlacements) == nil)
        #expect(RTPSOutcomeMatches.underlyingError(.noAction) == nil)
        #expect(
            RTPSOutcomeMatches.underlyingError(.failure(.missingRequiredFields)) == nil
        )
        #expect(
            RTPSOutcomeMatches.underlyingError(.failure(.api(message: "error"))) == nil
        )
    }
}
