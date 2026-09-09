@preconcurrency import RecaptchaEnterprise

package protocol RecaptchaVendorClient: Sendable {
    func execute(
        withAction action: RecaptchaAction,
        withTimeout timeout: Double
    ) async throws -> String
}

extension RecaptchaClient: RecaptchaVendorClient {}
