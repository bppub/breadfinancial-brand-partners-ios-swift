import Foundation
import Testing

@testable import BreadPartnersCore

@Suite struct RTPSServiceTestDoublesTests {
    @Test
    func stubRecaptchaProviderDefaultsToASuccessfulTokenAndRecordsExecution() async throws {
        let recaptcha = StubRecaptchaProvider()

        let token = try await recaptcha.execute(
            siteKey: "site-key",
            action: "checkout",
            timeout: 10_000,
            debug: true
        )

        #expect(token == "recaptcha-token")
        await #expect(recaptcha.callCount == 1)
        await #expect(recaptcha.lastSiteKey == "site-key")
        await #expect(recaptcha.lastAction == "checkout")
        await #expect(recaptcha.lastTimeout == 10_000)
        await #expect(recaptcha.lastDebug == true)
    }

    @Test
    func stubRecaptchaProviderCanReturnAConfiguredToken() async throws {
        let recaptcha = StubRecaptchaProvider(result: .success("custom-token"))

        let token = try await recaptcha.execute(
            siteKey: "site-key",
            action: "checkout",
            timeout: 10_000,
            debug: false
        )

        #expect(token == "custom-token")
    }

    @Test
    func stubRecaptchaProviderCanThrowAConfiguredFailure() async {
        let recaptcha = StubRecaptchaProvider(
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
    }

    @Test
    func spyNetworkClientStartsWithNoRequestsAndReturnsConfiguredData() async throws {
        let responseData = Data("response".utf8)
        let network = SpyRTPSNetworkClient(responseData: responseData)
        let request = RTPSNetworkRequest(
            url: RTPSFixtures.URLs.prescreen,
            method: .POST,
            headers: ["X-Test": "value"],
            cookies: "cookie=value",
            body: Data("request".utf8)
        )

        await #expect(network.requests.isEmpty)
        let result = try await network.send(request)

        #expect(result == responseData)
        let recordedRequest = await network.requests.first
        #expect(recordedRequest?.url == request.url)
        #expect(recordedRequest?.method == request.method)
        #expect(recordedRequest?.headers == request.headers)
        #expect(recordedRequest?.cookies == request.cookies)
        #expect(recordedRequest?.body == request.body)
    }

    @Test
    func spyNetworkClientRecordsRequestsBeforeThrowingAConfiguredFailure() async {
        let request = RTPSNetworkRequest(
            url: RTPSFixtures.URLs.prescreen,
            method: .POST
        )
        let network = SpyRTPSNetworkClient(
            failure: NSError(domain: "Network", code: 500)
        )

        do {
            _ = try await network.send(request)
            Issue.record("Expected the configured network failure")
        } catch {
            #expect((error as NSError).domain == "Network")
            #expect((error as NSError).code == 500)
            let recordedRequest = await network.requests.first
            #expect(recordedRequest?.url == request.url)
            #expect(recordedRequest?.method == request.method)
        }
    }

    @Test
    func stubRequestBuilderReturnsConfiguredRequestAndRecordsTheToken() {
        let request = RTPSRequest(
            urlPath: "/custom",
            reCaptchaToken: "configured-token"
        )
        let builder = StubRTPSRequestBuilder(request: request)

        let result = builder.build(
            merchantConfiguration: MerchantConfiguration(),
            rtpsData: RTPSData(),
            recaptchaToken: "token-123"
        )

        #expect(result.urlPath == request.urlPath)
        #expect(result.reCaptchaToken == request.reCaptchaToken)
        #expect(builder.receivedTokens == ["token-123"])
    }

    @Test
    func stubResponseDecoderReturnsTheConfiguredResponse() throws {
        let response = RTPSFixtures.Response.approved(prescreenId: 42)
        let decoder = StubRTPSResponseDecoder(response: response)

        let result = try decoder.decode(RTPSResponse.self, from: Data())

        #expect(result.returnCode == "01")
        #expect(result.prescreenId == 42)
        #expect(result.cardType == "storeCard")
    }

    @Test
    func stubResponseDecoderRejectsUnsupportedResponseTypes() {
        let decoder = StubRTPSResponseDecoder()

        do {
            _ = try decoder.decode(String.self, from: Data())
            Issue.record("Expected the decoder to reject an unsupported response type")
        } catch {
            let nsError = error as NSError
            #expect(nsError.domain == "StubRTPSResponseDecoder")
            #expect(nsError.code == 1)
            #expect(nsError.localizedDescription == "No response configured")
        }
    }

    @Test
    func stubResponseDecoderCanThrowAConfiguredFailure() {
        let decoder = StubRTPSResponseDecoder(
            failure: NSError(domain: "Decoding", code: 1)
        )

        do {
            _ = try decoder.decode(RTPSResponse.self, from: Data())
            Issue.record("Expected the configured decoding failure")
        } catch {
            #expect((error as NSError).domain == "Decoding")
            #expect((error as NSError).code == 1)
        }
    }
}
