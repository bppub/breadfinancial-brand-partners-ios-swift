import Foundation
import Testing

@testable import BreadPartnersCore

@Suite struct RTPSServiceTests {

    // MARK: - Flow selection

    @Test
    func batchPrescreenSkipsRecaptchaAndNetwork() async {
        let recaptcha = StubRecaptchaProvider()
        let network = HTTPClientSpy()
        let service = RTPSService(
            dependencies: RTPSFixtures.dependencies(recaptcha: recaptcha, network: network)
        )

        let outcome = await service.execute(
            RTPSFixtures.input(rtpsData: RTPSData(customerAcceptedOffer: true))
        )

        #expect(RTPSOutcomeMatches.skipToPlacements(outcome))
        await #expect(recaptcha.callCount == 0)
        await #expect(network.requests.isEmpty)
    }

    @Test
    func virtualLookupSkipsRecaptcha() async {
        let recaptcha = StubRecaptchaProvider()
        let builder = StubRTPSRequestBuilder()
        let service = RTPSService(
            dependencies: RTPSFixtures.dependencies(
                recaptcha: recaptcha,
                network: HTTPClientSpy(),
                requestBuilder: builder
            )
        )

        _ = await service.execute(RTPSFixtures.input(rtpsData: RTPSData(prescreenId: 42)))

        await #expect(recaptcha.callCount == 0)
        #expect(builder.receivedTokens == [nil])
    }

    @Test
    func prescreenRequestsTokenOnceAndForwardsItToTheBuilder() async {
        let recaptcha = StubRecaptchaProvider(result: .success("token-123"))
        let builder = StubRTPSRequestBuilder()
        let service = RTPSService(
            dependencies: RTPSFixtures.dependencies(
                recaptcha: recaptcha,
                network: HTTPClientSpy(),
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
        let service = RTPSService(
            dependencies: RTPSFixtures.dependencies(
                network: HTTPClientSpy(),
                responseDecoder: StubRTPSResponseDecoder(
                    response: RTPSFixtures.Response.approved()
                )
            )
        )

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
        let network = HTTPClientSpy()
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

        #expect(RTPSOutcomeMatches.missingRequiredFields(outcome))
        await #expect(recaptcha.callCount == 0)
        await #expect(network.requests.isEmpty)
        #expect(log.recordedMessages == ["Buyer information is missing or wrong."])
    }

    @Test
    func virtualLookupSkipsValidation() async {
        let network = HTTPClientSpy()
        let service = RTPSService(dependencies: RTPSFixtures.dependencies(network: network))

        let outcome = await service.execute(
            RTPSFixtures.input(
                merchantConfiguration: MerchantConfiguration(),
                rtpsData: RTPSData(prescreenId: 42)
            )
        )

        #expect(RTPSOutcomeMatches.missingRequiredFields(outcome) == false)
        await #expect(network.requests.count == 1)
    }

    // MARK: - Request construction

    @Test
    func prescreenSelectsPrescreenEndpoint() async {
        let network = HTTPClientSpy()
        let service = RTPSService(dependencies: RTPSFixtures.dependencies(network: network))

        _ = await service.execute(RTPSFixtures.input(rtpsData: RTPSData()))

        await #expect(network.requests.first?.url == RTPSFixtures.URLs.prescreen)
    }

    @Test
    func virtualLookupSelectsLookupEndpoint() async {
        let network = HTTPClientSpy()
        let service = RTPSService(dependencies: RTPSFixtures.dependencies(network: network))

        _ = await service.execute(RTPSFixtures.input(rtpsData: RTPSData(prescreenId: 42)))

        await #expect(network.requests.first?.url == RTPSFixtures.URLs.virtualLookup)
    }

    @Test
    func sendsIntegrationKeyAndRequestedWithHeaders() async {
        let network = HTTPClientSpy()
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
        let network = HTTPClientSpy()
        let service = RTPSService(dependencies: RTPSFixtures.dependencies(network: network))

        _ = await service.execute(
            RTPSFixtures.input(rtpsData: RTPSData(), cookies: "visid=abc")
        )

        await #expect(network.requests.first?.cookies == "visid=abc")
    }

    // MARK: - Response interpretation

    @Test
    func approvedResponseProceedsToPlacements() async {
        let service = RTPSService(
            dependencies: RTPSFixtures.dependencies(
                network: HTTPClientSpy(),
                responseDecoder: StubRTPSResponseDecoder(
                    response: RTPSFixtures.Response.model(returnCode: "01", prescreenId: 9001)
                )
            )
        )

        let outcome = await service.execute(RTPSFixtures.input(rtpsData: RTPSData()))

        #expect(RTPSOutcomeMatches.proceedResponse(outcome)?.prescreenId == 9001)
        #expect(RTPSOutcomeMatches.proceedResponse(outcome)?.cardType == "storeCard")
    }

    @Test
    func accountFoundResponseProceedsToPlacements() async {
        let service = RTPSService(
            dependencies: RTPSFixtures.dependencies(
                network: HTTPClientSpy(),
                responseDecoder: StubRTPSResponseDecoder(
                    response: RTPSFixtures.Response.model(returnCode: "0", prescreenId: 55)
                )
            )
        )

        let outcome = await service.execute(RTPSFixtures.input(rtpsData: RTPSData(prescreenId: 55)))

        #expect(RTPSOutcomeMatches.proceedResponse(outcome)?.prescreenId == 55)
    }

    @Test(arguments: ["10", "11", "12", "unknown"])
    func nonApprovedReturnCodeProducesNoAction(returnCode: String) async {
        let service = RTPSService(
            dependencies: RTPSFixtures.dependencies(
                network: HTTPClientSpy(),
                responseDecoder: StubRTPSResponseDecoder(
                    response: RTPSFixtures.Response.model(
                        returnCode: returnCode,
                        prescreenId: 9001
                    )
                )
            )
        )

        let outcome = await service.execute(RTPSFixtures.input(rtpsData: RTPSData()))

        #expect(RTPSOutcomeMatches.noAction(outcome))
    }

    @Test
    func missingReturnCodeDefaultsToNoAction() async {
        let service = RTPSService(
            dependencies: RTPSFixtures.dependencies(
                network: HTTPClientSpy(),
                responseDecoder: StubRTPSResponseDecoder(
                    response: RTPSFixtures.Response.model(returnCode: nil, prescreenId: 9001)
                )
            )
        )

        let outcome = await service.execute(RTPSFixtures.input(rtpsData: RTPSData()))

        #expect(RTPSOutcomeMatches.noAction(outcome))
    }

    @Test
    func approvedWithoutPrescreenIdProducesNoAction() async {
        let service = RTPSService(
            dependencies: RTPSFixtures.dependencies(
                network: HTTPClientSpy(),
                responseDecoder: StubRTPSResponseDecoder(
                    response: RTPSFixtures.Response.model(returnCode: "01", prescreenId: nil)
                )
            )
        )

        let outcome = await service.execute(RTPSFixtures.input(rtpsData: RTPSData()))

        #expect(RTPSOutcomeMatches.noAction(outcome))
    }

    // MARK: - Failure classification

    @Test
    func networkFailureBecomesTypedApiFailure() async {
        let service = RTPSService(
            dependencies: RTPSFixtures.dependencies(
                network: HTTPClientSpy(
                    failure: NSError(
                        domain: "Network",
                        code: 500,
                        userInfo: [NSLocalizedDescriptionKey: "request timed out"]
                    )
                )
            )
        )

        let outcome = await service.execute(RTPSFixtures.input(rtpsData: RTPSData()))

        #expect(RTPSOutcomeMatches.apiMessage(outcome) == "request timed out")
    }

    @Test
    func decodeFailureBecomesTypedApiFailure() async {
        let service = RTPSService(
            dependencies: RTPSFixtures.dependencies(
                network: HTTPClientSpy(),
                responseDecoder: StubRTPSResponseDecoder(
                    failure: NSError(
                        domain: "Decoding",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "malformed payload"]
                    )
                )
            )
        )

        let outcome = await service.execute(RTPSFixtures.input(rtpsData: RTPSData()))

        #expect(RTPSOutcomeMatches.apiMessage(outcome) == "malformed payload")
    }

    @Test
    func recaptchaFailureBecomesTypedApiFailure() async {
        let network = HTTPClientSpy()
        let service = RTPSService(
            dependencies: RTPSFixtures.dependencies(
                recaptcha: StubRecaptchaProvider(
                    result: .failure(
                        NSError(
                            domain: "Recaptcha",
                            code: 7,
                            userInfo: [NSLocalizedDescriptionKey: "token unavailable"]
                        )
                    )
                ),
                network: network
            )
        )

        let outcome = await service.execute(RTPSFixtures.input(rtpsData: RTPSData()))

        #expect(RTPSOutcomeMatches.apiMessage(outcome) == "token unavailable")
        await #expect(network.requests.isEmpty)
    }

    @Test
    func incapsulaErrorBecomesChallenge() async {
        let service = RTPSService(
            dependencies: RTPSFixtures.dependencies(
                network: HTTPClientSpy(failure: RTPSFixtures.Error.incapsula())
            )
        )

        let outcome = await service.execute(RTPSFixtures.input(rtpsData: RTPSData()))

        #expect(RTPSOutcomeMatches.challengePayload(outcome)?.htmlContent == "<html>challenge</html>")
        #expect(RTPSOutcomeMatches.challengePayload(outcome)?.originalURL == "https://challenge.test")
    }

    @Test
    func incapsulaErrorWithoutHTMLFallsBackToUnderlyingFailure() async {
        let service = RTPSService(
            dependencies: RTPSFixtures.dependencies(
                network: HTTPClientSpy(
                    failure: RTPSFixtures.Error.incapsula(htmlContent: nil)
                )
            )
        )

        let outcome = await service.execute(RTPSFixtures.input(rtpsData: RTPSData()))

        #expect(RTPSOutcomeMatches.underlyingError(outcome)?.domain == "IncapsulaChallenge")
    }

    @Test
    func incapsulaErrorWithoutURLFallsBackToUnderlyingFailure() async {
        let service = RTPSService(
            dependencies: RTPSFixtures.dependencies(
                network: HTTPClientSpy(
                    failure: RTPSFixtures.Error.incapsula(url: nil)
                )
            )
        )

        let outcome = await service.execute(RTPSFixtures.input(rtpsData: RTPSData()))

        #expect(RTPSOutcomeMatches.underlyingError(outcome)?.domain == "IncapsulaChallenge")
    }
}
