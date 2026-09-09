import BreadPartnersCore
@preconcurrency import RecaptchaEnterprise

package actor LiveRecaptchaProvider: RecaptchaProviding {
    private let logger: Logger
    private var recaptchaClient: RecaptchaClient?

    package init(logger: Logger = Logger()) {
        self.logger = logger
    }

    package func execute(
        siteKey: String,
        action: String,
        timeout: Double,
        debug: Bool
    ) async throws -> String {
        try await fetchRecaptchaClient(siteKey: siteKey)

        guard let recaptchaClient else {
            return ""
        }

        do {
            let token = try await recaptchaClient.execute(
                withAction: .init(customAction: action),
                withTimeout: timeout
            )

            if debug {
                logger.logReCaptchaToken(token: token)
            }

            return token
        } catch let error as RecaptchaError {
            throw error
        }
    }

    private func fetchRecaptchaClient(siteKey: String) async throws {
        guard recaptchaClient == nil else {
            return
        }

        do {
            recaptchaClient = try await Recaptcha.fetchClient(withSiteKey: siteKey)
        } catch let error as RecaptchaError {
            throw error
        }
    }
}
