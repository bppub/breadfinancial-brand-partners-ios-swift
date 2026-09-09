package protocol RecaptchaProviding: Sendable {
    func execute(
        siteKey: String,
        action: String,
        timeout: Double,
        debug: Bool
    ) async throws -> String
}
