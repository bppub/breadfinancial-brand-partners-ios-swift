@preconcurrency import RecaptchaEnterprise

package protocol RecaptchaClientProviding: Sendable {
    func execute(
        action: String,
        timeout: Double
    ) async throws -> String
}

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

package final class LiveRecaptchaClient: RecaptchaClientProviding, @unchecked Sendable {
    private let client: RecaptchaClient

    package init(client: RecaptchaClient) {
        self.client = client
    }

    package func execute(
        action: String,
        timeout: Double
    ) async throws -> String {
        try await client.execute(
            withAction: .init(customAction: action),
            withTimeout: timeout
        )
    }
}
