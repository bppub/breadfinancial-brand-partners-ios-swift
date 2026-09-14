package protocol RTPSRequestBuilding: Sendable {
    func build(
        merchantConfiguration: MerchantConfiguration,
        rtpsData: RTPSData,
        recaptchaToken: String?
    ) -> RTPSRequest
}
