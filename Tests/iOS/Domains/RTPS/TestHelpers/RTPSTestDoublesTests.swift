import Foundation
import Testing

@testable import BreadPartners

@Suite
struct RTPSTestDoublesTests {
    @Test
    func recaptchaStubUsesDefaultSuccessfulResult() async throws {
        let recaptcha = RecaptchaStub()

        let token = try await recaptcha.execute(
            siteKey: "default-site-key",
            action: "default-action",
            timeout: 1,
            debug: false
        )

        #expect(token == "test-token")
        await #expect(recaptcha.callCount == 1)
    }

    @Test
    func recaptchaStubReturnsConfiguredTokenAndRecordsArguments() async throws {
        let recaptcha = RecaptchaStub(result: .success("configured-token"))

        let token = try await recaptcha.execute(
            siteKey: "site-key",
            action: "checkout",
            timeout: 10_000,
            debug: true
        )

        #expect(token == "configured-token")
        await #expect(recaptcha.callCount == 1)
        await #expect(recaptcha.lastSiteKey == "site-key")
        await #expect(recaptcha.lastAction == "checkout")
        await #expect(recaptcha.lastTimeout == 10_000)
        await #expect(recaptcha.lastDebug == true)
    }

    @Test
    func recaptchaStubThrowsConfiguredFailure() async {
        let recaptcha = RecaptchaStub(
            result: .failure(NSError(domain: "Recaptcha", code: 7))
        )

        do {
            _ = try await recaptcha.execute(
                siteKey: "site-key",
                action: "checkout",
                timeout: 10_000,
                debug: false
            )
            Issue.record("Expected the configured reCAPTCHA failure")
        } catch {
            #expect((error as NSError).domain == "Recaptcha")
            #expect((error as NSError).code == 7)
        }

        await #expect(recaptcha.callCount == 1)
    }

    @Test
    func responseDecoderReturnsConfiguredResponsesInOrder() throws {
        let rtpsResponse = RTPSTestFixtures.Response.approved
        let placementsResponse = RTPSTestFixtures.Response.emptyPlacements
        let decoder = ResponseDecoderStub(
            responses: [
                .rtps(rtpsResponse),
                .placements(placementsResponse),
            ]
        )

        let decodedRTPS = try decoder.decode(RTPSResponse.self, from: Data())
        let decodedPlacements = try decoder.decode(PlacementsResponse.self, from: Data())

        #expect(decodedRTPS.prescreenId == rtpsResponse.prescreenId)
        #expect(decodedPlacements.placements?.isEmpty == true)
    }

    @Test
    func responseDecoderRejectsAnUnexpectedConfiguredResponseType() {
        let decoder = ResponseDecoderStub(
            responses: [.rtps(RTPSTestFixtures.Response.approved)]
        )

        do {
            _ = try decoder.decode(PlacementsResponse.self, from: Data())
            Issue.record("Expected the response decoder to reject the configured response type")
        } catch {
            let nsError = error as NSError
            #expect(nsError.domain == "ResponseDecoderStub")
            #expect(nsError.code == 2)
        }
    }

    @Test
    func responseDecoderRejectsAPlacementResponseWhenRTPSIsRequested() {
        let decoder = ResponseDecoderStub(
            responses: [.placements(RTPSTestFixtures.Response.emptyPlacements)]
        )

        do {
            _ = try decoder.decode(RTPSResponse.self, from: Data())
            Issue.record("Expected the response decoder to reject a placement response")
        } catch {
            let nsError = error as NSError
            #expect(nsError.domain == "ResponseDecoderStub")
            #expect(nsError.code == 2)
        }
    }

    @Test
    func responseDecoderThrowsWhenResponseQueueIsEmpty() {
        let decoder = ResponseDecoderStub(responses: [])

        do {
            _ = try decoder.decode(RTPSResponse.self, from: Data())
            Issue.record("Expected the response decoder to reject an empty queue")
        } catch {
            let nsError = error as NSError
            #expect(nsError.domain == "ResponseDecoderStub")
            #expect(nsError.code == 1)
            #expect(nsError.localizedDescription == "No response configured")
        }
    }

}
