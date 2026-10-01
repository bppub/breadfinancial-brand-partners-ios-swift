package struct RTPSDependencies: Sendable {
    package let recaptcha: any RecaptchaProviding
    package let requestBuilder: any RTPSRequestBuilding
    package let responseDecoder: any RTPSResponseDecoding

    package init(
        recaptcha: any RecaptchaProviding,
        requestBuilder: any RTPSRequestBuilding,
        responseDecoder: any RTPSResponseDecoding
    ) {
        self.recaptcha = recaptcha
        self.requestBuilder = requestBuilder
        self.responseDecoder = responseDecoder
    }
}
