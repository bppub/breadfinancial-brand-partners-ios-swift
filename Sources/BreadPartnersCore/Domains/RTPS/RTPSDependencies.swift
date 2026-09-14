package struct RTPSDependencies: Sendable {
    package let recaptcha: any RecaptchaProviding
    package let network: any RTPSNetworkClient
    package let requestBuilder: any RTPSRequestBuilding
    package let responseDecoder: any RTPSResponseDecoding

    package init(
        recaptcha: any RecaptchaProviding,
        network: any RTPSNetworkClient,
        requestBuilder: any RTPSRequestBuilding,
        responseDecoder: any RTPSResponseDecoding
    ) {
        self.recaptcha = recaptcha
        self.network = network
        self.requestBuilder = requestBuilder
        self.responseDecoder = responseDecoder
    }
}
