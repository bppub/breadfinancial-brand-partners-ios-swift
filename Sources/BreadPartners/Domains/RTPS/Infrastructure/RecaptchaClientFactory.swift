@preconcurrency import RecaptchaEnterprise

package protocol RecaptchaClientFactory: Sendable {
    func makeClient(siteKey: String) async throws -> (any RecaptchaClientProviding)?
}

package struct LiveRecaptchaClientFactory: RecaptchaClientFactory {
    package init() {}

    package func makeClient(siteKey: String) async throws -> (any RecaptchaClientProviding)? {
        LiveRecaptchaClient(
            client: try await Recaptcha.fetchClient(withSiteKey: siteKey)
        )
    }
}
