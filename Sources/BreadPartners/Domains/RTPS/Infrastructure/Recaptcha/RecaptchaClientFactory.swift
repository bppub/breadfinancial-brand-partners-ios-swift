@preconcurrency import RecaptchaEnterprise

package protocol RecaptchaClientLoader: Sendable {
    func fetchClient(siteKey: String) async throws -> any RecaptchaVendorClient
}

package protocol RecaptchaClientFactory: Sendable {
    func makeClient(siteKey: String) async throws -> (any RecaptchaClientProviding)?
}

package struct LiveRecaptchaClientFactory: RecaptchaClientFactory {
    private let clientLoader: any RecaptchaClientLoader

    package init(clientLoader: any RecaptchaClientLoader = LiveRecaptchaClientLoader()) {
        self.clientLoader = clientLoader
    }

    package func makeClient(siteKey: String) async throws -> (any RecaptchaClientProviding)? {
        LiveRecaptchaClient(
            client: try await clientLoader.fetchClient(siteKey: siteKey)
        )
    }
}

package struct LiveRecaptchaClientLoader: RecaptchaClientLoader {
    package init() {}

    package func fetchClient(siteKey: String) async throws -> any RecaptchaVendorClient {
        try await Recaptcha.fetchClient(withSiteKey: siteKey)
    }
}
