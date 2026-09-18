import Foundation
import Testing

@testable import BreadPartnersCore

@Suite struct RTPSServiceTests {

    // MARK: - Flow selection

    @Test
    func batchPrescreenSkipsRecaptchaAndNetwork() async {
        let recaptcha = StubRecaptchaProvider()
        let network = SpyRTPSNetworkClient()
        let service = RTPSService(
            dependencies: RTPSFixtures.dependencies(recaptcha: recaptcha, network: network)
        )

        let outcome = await service.execute(
            RTPSFixtures.input(rtpsData: RTPSData(customerAcceptedOffer: true))
        )

        #expect(isSkipToPlacements(outcome))
        await #expect(recaptcha.callCount == 0)
        await #expect(network.requests.isEmpty)
    }

    @Test
    func virtualLookupSkipsRecaptcha() async {
        let recaptcha = StubRecaptchaProvider()
        let builder = SpyRTPSRequestBuilder()
        let network = SpyRTPSNetworkClient(responseData: RTPSFixtures.Response.json())
        let service = RTPSService(
            dependencies: RTPSFixtures.dependencies(
                recaptcha: recaptcha,
                network: network,
                requestBuilder: builder
            )
        )

        _ = await service.execute(RTPSFixtures.input(rtpsData: RTPSData(prescreenId: 42)))

        await #expect(recaptcha.callCount == 0)
        #expect(builder.receivedTokens == [nil])
    }

    @Test
    func prescreenRequestsTokenOnceAndForwardsItToTheBuilder() async {
        let recaptcha = StubRecaptchaProvider(token: "token-123")
        let builder = SpyRTPSRequestBuilder()
        let network = SpyRTPSNetworkClient(responseData: RTPSFixtures.Response.json())
        let service = RTPSService(
            dependencies: RTPSFixtures.dependencies(
                recaptcha: recaptcha,
                network: network,
                requestBuilder: builder
            )
        )

        _ = await service.execute(
            RTPSFixtures.input(rtpsData: RTPSData(), siteKey: "site-abc", isLoggingEnabled: true)
        )

        await #expect(recaptcha.callCount == 1)
        await #expect(recaptcha.lastSiteKey == "site-abc")
        await #expect(recaptcha.lastAction == "checkout")
        await #expect(recaptcha.lastTimeout == 10000)
        await #expect(recaptcha.lastDebug == true)
        #expect(builder.receivedTokens == ["token-123"])
    }

    @Test
    func virtualLookupLogsThatRecaptchaWasSkipped() async {
        let log = LogCapture()
        let network = SpyRTPSNetworkClient(responseData: RTPSFixtures.Response.json())
        let service = RTPSService(dependencies: RTPSFixtures.dependencies(network: network))

        _ = await service.execute(
            RTPSFixtures.input(
                rtpsData: RTPSData(prescreenId: 42),
                log: log.record
            )
        )

        #expect(
            log.recordedMessages == [
                "Skipping reCaptcha token generation for virtual lookup call.",
                "No Cookies",
                "PreScreenID:Result: approved",
            ])
    }

    // MARK: - Validation

    @Test(arguments: RTPSFixtures.MerchantConfigurationFixture.RequiredField.allCases)
    func missingRequiredFieldPreventsNetworkCall(
        field: RTPSFixtures.MerchantConfigurationFixture.RequiredField
    ) async {
        let log = LogCapture()
        let recaptcha = StubRecaptchaProvider()
        let network = SpyRTPSNetworkClient()
        let service = RTPSService(
            dependencies: RTPSFixtures.dependencies(recaptcha: recaptcha, network: network)
        )

        let outcome = await service.execute(
            RTPSFixtures.input(
                merchantConfiguration: RTPSFixtures.MerchantConfigurationFixture.missing(field),
                rtpsData: RTPSData(),
                log: log.record
            )
        )

        #expect(isMissingRequiredFields(outcome))
        await #expect(recaptcha.callCount == 0)
        await #expect(network.requests.isEmpty)
        #expect(log.recordedMessages == ["Buyer information is missing or wrong."])
    }

    @Test
    func virtualLookupSkipsValidation() async {
        let network = SpyRTPSNetworkClient(responseData: RTPSFixtures.Response.json())
        let service = RTPSService(dependencies: RTPSFixtures.dependencies(network: network))

        let outcome = await service.execute(
            RTPSFixtures.input(
                merchantConfiguration: MerchantConfiguration(),
                rtpsData: RTPSData(prescreenId: 42)
            )
        )

        #expect(isMissingRequiredFields(outcome) == false)
        await #expect(network.requests.count == 1)
    }

    // MARK: - Request construction

    @Test
    func prescreenSelectsPrescreenEndpoint() async {
        let network = SpyRTPSNetworkClient(responseData: RTPSFixtures.Response.json())
        let service = RTPSService(dependencies: RTPSFixtures.dependencies(network: network))

        _ = await service.execute(RTPSFixtures.input(rtpsData: RTPSData()))

        await #expect(network.requests.first?.url == RTPSFixtures.URLs.prescreen)
    }

    @Test
    func virtualLookupSelectsLookupEndpoint() async {
        let network = SpyRTPSNetworkClient(responseData: RTPSFixtures.Response.json())
        let service = RTPSService(dependencies: RTPSFixtures.dependencies(network: network))

        _ = await service.execute(RTPSFixtures.input(rtpsData: RTPSData(prescreenId: 42)))

        await #expect(network.requests.first?.url == RTPSFixtures.URLs.virtualLookup)
    }

    @Test
    func sendsIntegrationKeyAndRequestedWithHeaders() async {
        let network = SpyRTPSNetworkClient(responseData: RTPSFixtures.Response.json())
        let service = RTPSService(dependencies: RTPSFixtures.dependencies(network: network))

        _ = await service.execute(
            RTPSFixtures.input(rtpsData: RTPSData(), integrationKey: "key-777")
        )

        let request = await network.requests.first
        #expect(request?.method == .POST)
        #expect(request?.headers["X-Client-Key"] == "key-777")
        #expect(request?.headers["X-Requested-With"] == "XMLHttpRequest")
        #expect(request?.body?.isEmpty == false)
    }

    @Test
    func forwardsCookiesWhenPresent() async {
        let network = SpyRTPSNetworkClient(responseData: RTPSFixtures.Response.json())
        let service = RTPSService(dependencies: RTPSFixtures.dependencies(network: network))

        _ = await service.execute(
            RTPSFixtures.input(rtpsData: RTPSData(), cookies: "visid=abc")
        )

        await #expect(network.requests.first?.cookies == "visid=abc")
    }

    // MARK: - Response interpretation

    @Test
    func approvedResponseProceedsToPlacements() async {
        let network = SpyRTPSNetworkClient(
            responseData: RTPSFixtures.Response.json(returnCode: "01", prescreenId: 9001)
        )
        let service = RTPSService(dependencies: RTPSFixtures.dependencies(network: network))

        let outcome = await service.execute(RTPSFixtures.input(rtpsData: RTPSData()))

        #expect(proceedResponse(outcome)?.prescreenId == 9001)
        #expect(proceedResponse(outcome)?.cardType == "storeCard")
    }

    @Test
    func accountFoundResponseProceedsToPlacements() async {
        let network = SpyRTPSNetworkClient(
            responseData: RTPSFixtures.Response.json(returnCode: "0", prescreenId: 55)
        )
        let service = RTPSService(dependencies: RTPSFixtures.dependencies(network: network))

        let outcome = await service.execute(RTPSFixtures.input(rtpsData: RTPSData(prescreenId: 55)))

        #expect(proceedResponse(outcome)?.prescreenId == 55)
    }

    @Test(arguments: ["10", "11", "12", "unknown"])
    func nonApprovedReturnCodeProducesNoAction(returnCode: String) async {
        let network = SpyRTPSNetworkClient(
            responseData: RTPSFixtures.Response.json(returnCode: returnCode, prescreenId: 9001)
        )
        let service = RTPSService(dependencies: RTPSFixtures.dependencies(network: network))

        let outcome = await service.execute(RTPSFixtures.input(rtpsData: RTPSData()))

        #expect(isNoAction(outcome))
    }

    @Test
    func missingReturnCodeDefaultsToNoAction() async {
        let network = SpyRTPSNetworkClient(
            responseData: RTPSFixtures.Response.json(returnCode: nil, prescreenId: 9001)
        )
        let service = RTPSService(dependencies: RTPSFixtures.dependencies(network: network))

        let outcome = await service.execute(RTPSFixtures.input(rtpsData: RTPSData()))

        #expect(isNoAction(outcome))
    }

    @Test
    func approvedWithoutPrescreenIdProducesNoAction() async {
        let network = SpyRTPSNetworkClient(
            responseData: RTPSFixtures.Response.json(returnCode: "01", prescreenId: nil)
        )
        let service = RTPSService(dependencies: RTPSFixtures.dependencies(network: network))

        let outcome = await service.execute(RTPSFixtures.input(rtpsData: RTPSData()))

        #expect(isNoAction(outcome))
    }

    // MARK: - Failure classification

    @Test
    func networkFailureBecomesTypedApiFailure() async {
        let failure = NSError(
            domain: "Network",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "request timed out"]
        )
        let network = SpyRTPSNetworkClient(failure: failure)
        let service = RTPSService(dependencies: RTPSFixtures.dependencies(network: network))

        let outcome = await service.execute(RTPSFixtures.input(rtpsData: RTPSData()))

        #expect(apiMessage(outcome) == "request timed out")
    }

    @Test
    func decodeFailureBecomesTypedApiFailure() async {
        let decoder = StubRTPSResponseDecoder(
            failure: NSError(
                domain: "Decoding",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "malformed payload"]
            )
        )
        let network = SpyRTPSNetworkClient(responseData: RTPSFixtures.Response.json())
        let service = RTPSService(
            dependencies: RTPSFixtures.dependencies(network: network, responseDecoder: decoder)
        )

        let outcome = await service.execute(RTPSFixtures.input(rtpsData: RTPSData()))

        #expect(apiMessage(outcome) == "malformed payload")
    }

    @Test
    func recaptchaFailureBecomesTypedApiFailure() async {
        let recaptcha = StubRecaptchaProvider(
            failure: NSError(
                domain: "Recaptcha",
                code: 7,
                userInfo: [NSLocalizedDescriptionKey: "token unavailable"]
            )
        )
        let network = SpyRTPSNetworkClient()
        let service = RTPSService(
            dependencies: RTPSFixtures.dependencies(recaptcha: recaptcha, network: network)
        )

        let outcome = await service.execute(RTPSFixtures.input(rtpsData: RTPSData()))

        #expect(apiMessage(outcome) == "token unavailable")
        await #expect(network.requests.isEmpty)
    }

    @Test
    func incapsulaErrorBecomesChallenge() async {
        let network = SpyRTPSNetworkClient(failure: RTPSFixtures.Error.incapsula())
        let service = RTPSService(dependencies: RTPSFixtures.dependencies(network: network))

        let outcome = await service.execute(RTPSFixtures.input(rtpsData: RTPSData()))

        #expect(challengePayload(outcome)?.htmlContent == "<html>challenge</html>")
        #expect(challengePayload(outcome)?.originalURL == "https://challenge.test")
    }

    @Test
    func incapsulaErrorWithoutHTMLFallsBackToUnderlyingFailure() async {
        let network = SpyRTPSNetworkClient(failure: RTPSFixtures.Error.incapsula(htmlContent: nil))
        let service = RTPSService(dependencies: RTPSFixtures.dependencies(network: network))

        let outcome = await service.execute(RTPSFixtures.input(rtpsData: RTPSData()))

        #expect(underlyingError(outcome)?.domain == "IncapsulaChallenge")
    }

    @Test
    func incapsulaErrorWithoutURLFallsBackToUnderlyingFailure() async {
        let network = SpyRTPSNetworkClient(failure: RTPSFixtures.Error.incapsula(url: nil))
        let service = RTPSService(dependencies: RTPSFixtures.dependencies(network: network))

        let outcome = await service.execute(RTPSFixtures.input(rtpsData: RTPSData()))

        #expect(underlyingError(outcome)?.domain == "IncapsulaChallenge")
    }
}

// MARK: - Outcome matchers

private func isSkipToPlacements(_ outcome: RTPSOutcome) -> Bool {
    if case .skipToPlacements = outcome { return true }
    return false
}

private func isNoAction(_ outcome: RTPSOutcome) -> Bool {
    if case .noAction = outcome { return true }
    return false
}

private func isMissingRequiredFields(_ outcome: RTPSOutcome) -> Bool {
    if case .failure(.missingRequiredFields) = outcome { return true }
    return false
}

private func proceedResponse(_ outcome: RTPSOutcome) -> RTPSResponse? {
    if case .proceedToPlacements(let response) = outcome { return response }
    return nil
}

private func challengePayload(_ outcome: RTPSOutcome) -> (htmlContent: String, originalURL: String)? {
    if case .challenge(let htmlContent, let originalURL) = outcome {
        return (htmlContent, originalURL)
    }
    return nil
}

private func apiMessage(_ outcome: RTPSOutcome) -> String? {
    if case .failure(.api(let message)) = outcome { return message }
    return nil
}

private func underlyingError(_ outcome: RTPSOutcome) -> NSError? {
    if case .failure(.underlying(let error)) = outcome { return error }
    return nil
}
