@preconcurrency import RecaptchaEnterprise

package protocol RecaptchaClientProviding: Sendable {
    func execute(
        action: String,
        timeout: Double
    ) async throws -> String
}

package final class LiveRecaptchaClient: RecaptchaClientProviding, @unchecked Sendable {
    private let client: any RecaptchaVendorClient

    package init(client: any RecaptchaVendorClient) {
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
