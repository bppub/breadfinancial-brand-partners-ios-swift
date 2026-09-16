import RecaptchaEnterprise

protocol RecaptchaClientProviding: Sendable {
    func execute(
        action: String,
        timeout: Double
    ) async throws -> String
}

protocol RecaptchaClientFactory: Sendable {
    func makeClient(siteKey: String) async throws -> (any RecaptchaClientProviding)?
}

// Live Recaptcha functionality must be tested via integration testing.

final class LiveRecaptchaClient: RecaptchaClientProviding, @unchecked Sendable {
    private let client: RecaptchaClient

    init(client: RecaptchaClient) {
        self.client = client
    }

    func execute(
        action: String,
        timeout: Double
    ) async throws -> String {
        try await client.execute(
            withAction: .init(customAction: action),
            withTimeout: timeout
        )
    }
}

struct LiveRecaptchaClientFactory: RecaptchaClientFactory {
    func makeClient(siteKey: String) async throws -> (any RecaptchaClientProviding)? {
        return LiveRecaptchaClient(
            client: try await Recaptcha.fetchClient(withSiteKey: siteKey)
        )
    }
}
