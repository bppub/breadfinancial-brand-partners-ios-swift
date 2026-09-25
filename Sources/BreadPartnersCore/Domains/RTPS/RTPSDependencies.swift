package struct RTPSDependencies: Sendable {
    package let recaptcha: any RecaptchaProviding
    package let httpClient: any HTTPClient
    package let requestBuilder: any RTPSRequestBuilding
    package let responseDecoder: any RTPSResponseDecoding

    package init(
        recaptcha: any RecaptchaProviding,
        httpClient: any HTTPClient,
        requestBuilder: any RTPSRequestBuilding,
        responseDecoder: any RTPSResponseDecoding
    ) {
        self.recaptcha = recaptcha
        self.httpClient = httpClient
        self.requestBuilder = requestBuilder
        self.responseDecoder = responseDecoder
    }
}
