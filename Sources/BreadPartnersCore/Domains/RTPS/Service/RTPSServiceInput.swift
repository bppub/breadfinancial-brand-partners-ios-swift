import Foundation

/// Everything `RTPSService` needs for one execution, supplied by the caller.
///
/// Endpoints and the reCAPTCHA site key are resolved by the SDK target so Core stays platform-neutral.
package struct RTPSServiceInput: Sendable {
    package let merchantConfiguration: MerchantConfiguration
    package let rtpsData: RTPSData
    package let integrationKey: String
    package let siteKey: String
    package let prescreenURL: URL
    package let virtualLookupURL: URL
    package let cookies: String?
    package let isLoggingEnabled: Bool
    /// Caller-supplied sink; the SDK logger already gates on its own logging flag.
    package let log: @Sendable (String) -> Void

    package init(
        merchantConfiguration: MerchantConfiguration,
        rtpsData: RTPSData,
        integrationKey: String,
        siteKey: String,
        prescreenURL: URL,
        virtualLookupURL: URL,
        cookies: String? = nil,
        isLoggingEnabled: Bool = false,
        log: @escaping @Sendable (String) -> Void = { _ in }
    ) {
        self.merchantConfiguration = merchantConfiguration
        self.rtpsData = rtpsData
        self.integrationKey = integrationKey
        self.siteKey = siteKey
        self.prescreenURL = prescreenURL
        self.virtualLookupURL = virtualLookupURL
        self.cookies = cookies
        self.isLoggingEnabled = isLoggingEnabled
        self.log = log
    }
}
