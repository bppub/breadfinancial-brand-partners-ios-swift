import Foundation
import Testing

@testable import BreadPartners

@Suite
struct RTPSApiTestDoublesTests {
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
    func HTTPClientSpyReturnsQueuedDataAndRecordsEachRequest() async throws {
        let firstData = Data("first".utf8)
        let secondData = Data("second".utf8)
        let httpClient = HTTPClientSpy(
            outcomes: [.success(firstData), .success(secondData)]
        )
        let firstRequest = HTTPRequest(
            url: RTPSApiFixtures.URLs.prescreen,
            method: .POST
        )
        let secondRequest = HTTPRequest(
            url: RTPSApiFixtures.URLs.virtualLookup,
            method: .POST
        )

        #expect(try await httpClient.request(firstRequest) == firstData)
        #expect(try await httpClient.request(secondRequest) == secondData)
        #expect(await httpClient.requestCount == 2)
        #expect(await httpClient.requests.map(\.url) == [firstRequest.url, secondRequest.url])
    }

    @Test
    func HTTPClientSpyThrowsConfiguredFailureAfterRecordingRequest() async {
        let httpClient = HTTPClientSpy(
            outcomes: [.failure(NSError(domain: "Network", code: 500))]
        )
        let request = HTTPRequest(
            url: RTPSApiFixtures.URLs.prescreen,
            method: .POST
        )

        do {
            _ = try await httpClient.request(request)
            Issue.record("Expected the configured network failure")
        } catch {
            #expect((error as NSError).domain == "Network")
            #expect((error as NSError).code == 500)
        }

        #expect(await httpClient.requestCount == 1)
    }

    @Test
    func HTTPClientSpyReturnsEmptyDataWhenQueueIsExhausted() async throws {
        let httpClient = HTTPClientSpy(outcomes: [])
        let request = HTTPRequest(
            url: RTPSApiFixtures.URLs.prescreen,
            method: .POST
        )

        #expect(try await httpClient.request(request) == Data())
        #expect(await httpClient.requestCount == 1)
    }

    @Test
    func responseDecoderReturnsConfiguredResponsesInOrder() throws {
        let rtpsResponse = RTPSApiFixtures.Response.approved
        let placementsResponse = RTPSApiFixtures.Response.emptyPlacements
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
            responses: [.rtps(RTPSApiFixtures.Response.approved)]
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
            responses: [.placements(RTPSApiFixtures.Response.emptyPlacements)]
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

    @Test
    func eventCaptureRecordsEventsAndReportsSDKErrors() {
        let capture = EventCapture()

        #expect(capture.first == nil)
        #expect(capture.eventCount == 0)
        #expect(capture.containsSDKError == false)

        capture.record(.textClicked)
        capture.record(.onSDKEventLog(logs: "one"))
        capture.record(.sdkError(error: NSError(domain: "SDK", code: 1)))

        #expect(capture.eventCount == 3)
        guard let first = capture.first else {
            Issue.record("Expected EventCapture to preserve the first event")
            return
        }
        if case .textClicked = first {
        } else {
            Issue.record("Expected EventCapture to preserve the first event")
        }
        #expect(capture.containsSDKError)
    }
}
