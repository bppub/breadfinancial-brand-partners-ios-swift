import Foundation

/// Owns the RTPS workflow: flow selection, validation, token acquisition, request/response handling.
///
/// Creates no UI and performs no event translation.
package struct RTPSService: Sendable {
    private let dependencies: RTPSDependencies

    package init(dependencies: RTPSDependencies) {
        self.dependencies = dependencies
    }

    package func execute(_ input: RTPSServiceInput) async -> RTPSOutcome {
        // Batch prescreen enters with an offer already accepted, so RTPS is skipped entirely.
        if input.rtpsData.customerAcceptedOffer == true {
            return .skipToPlacements
        }

        let isPrescreen = input.rtpsData.prescreenId == nil

        if isPrescreen, !RTPSPrescreenValidator.hasRequiredFields(in: input.merchantConfiguration) {
            input.log("Buyer information is missing or wrong.")
            return .failure(.missingRequiredFields)
        }

        do {
            let recaptchaToken = try await recaptchaToken(for: input, isPrescreen: isPrescreen)

            input.log(
                input.cookies != nil
                    ? "Attaching cookies to RTPS request: \(String(describing: input.cookies))"
                    : "No Cookies"
            )

            let request = dependencies.requestBuilder.build(
                merchantConfiguration: input.merchantConfiguration,
                rtpsData: input.rtpsData,
                recaptchaToken: recaptchaToken
            )

            let data = try await dependencies.httpClient.request(
                HTTPRequest(
                    url: isPrescreen ? input.prescreenURL : input.virtualLookupURL,
                    method: .POST,
                    headers: [
                        RTPSRequestHeaders.clientKey: input.integrationKey,
                        RTPSRequestHeaders.requestedWith: RTPSRequestHeaders.xmlHttpRequest,
                    ],
                    cookies: input.cookies,
                    body: try JSONEncoder().encode(request)
                )
            )

            let response: RTPSResponse = try dependencies.responseDecoder.decode(
                RTPSResponse.self,
                from: data
            )

            let result = RTPSResult(returnCode: response.returnCode)

            input.log("PreScreenID:Result: \(result)")

            // A silent flow: anything other than an approval with a prescreen id produces no UI.
            guard result == .approved || result == .accountFound, response.prescreenId != nil else {
                return .noAction
            }

            return .proceedToPlacements(response)
        } catch let error as NSError {
            return mapErrorToOutcome(for: error)
        }
    }

    private func recaptchaToken(
        for input: RTPSServiceInput,
        isPrescreen: Bool
    ) async throws -> String? {
        guard isPrescreen else {
            input.log("Skipping reCaptcha token generation for virtual lookup call.")
            return nil
        }

        return try await dependencies.recaptcha.execute(
            siteKey: input.siteKey,
            action: RTPSRecaptcha.action,
            timeout: RTPSRecaptcha.timeout,
            debug: input.isLoggingEnabled
        )
    }

    private func mapErrorToOutcome(for error: NSError) -> RTPSOutcome {
        guard error.domain == NetworkChallengeConstants.domain else {
            return .failure(.api(message: error.localizedDescription))
        }

        guard let htmlContent = error.userInfo[NetworkChallengeConstants.htmlContentKey] as? String,
            let originalURL = error.userInfo[NetworkChallengeConstants.urlKey] as? String
        else {
            return .failure(.underlying(error))
        }

        return .challenge(htmlContent: htmlContent, originalURL: originalURL)
    }
}
