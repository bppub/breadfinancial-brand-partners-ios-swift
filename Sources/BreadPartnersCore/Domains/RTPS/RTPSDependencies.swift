package struct RTPSDependencies: Sendable {
    package let recaptcha: any RecaptchaProviding

    package init(recaptcha: any RecaptchaProviding) {
        self.recaptcha = recaptcha
    }
}
