package struct RTPSRequestBuilder: RTPSRequestBuilding, Sendable {
    package init() {}

    package func build(
        merchantConfiguration: MerchantConfiguration,
        rtpsData: RTPSData,
        recaptchaToken: String?
    ) -> RTPSRequest {
        let buyer = merchantConfiguration.buyer

        if rtpsData.prescreenId == nil {
            return RTPSRequest(
                urlPath: rtpsData.screenName.takeIfNotEmpty(),
                firstName: buyer?.givenName.takeIfNotEmpty(),
                lastName: buyer?.familyName.takeIfNotEmpty(),
                address1: buyer?.billingAddress?.address1,
                city: buyer?.billingAddress?.locality.takeIfNotEmpty(),
                state: buyer?.billingAddress?.region.takeIfNotEmpty(),
                zip: buyer?.billingAddress?.postalCode.takeIfNotEmpty(),
                storeNumber: merchantConfiguration.storeNumber.takeIfNotEmpty(),
                location: rtpsData.locationType?.rawValue,
                channel: merchantConfiguration.channel.takeIfNotEmpty(),
                subchannel: merchantConfiguration.subchannel.takeIfNotEmpty(),
                reCaptchaToken: recaptchaToken,
                mockResponse: rtpsData.mockResponse?.rawValue,
                overrideConfig: RTPSRequest.OverrideConfig(enhancedPresentment: true),
                customerAcceptedOffer: rtpsData.customerAcceptedOffer,
                mobilePhone: buyer?.phone.takeIfNotEmpty(),
                emailAddress: buyer?.email.takeIfNotEmpty(),
                alternativePhone: buyer?.alternativePhone.takeIfNotEmpty()
            )
        }

        return RTPSRequest(
            urlPath: rtpsData.screenName.takeIfNotEmpty(),
            location: rtpsData.locationType?.rawValue,
            channel: merchantConfiguration.channel.takeIfNotEmpty(),
            subchannel: merchantConfiguration.subchannel.takeIfNotEmpty(),
            mockResponse: rtpsData.mockResponse?.rawValue,
            overrideConfig: RTPSRequest.OverrideConfig(enhancedPresentment: true),
            prescreenId: String(rtpsData.prescreenId!),
            customerAcceptedOffer: rtpsData.customerAcceptedOffer
        )
    }
}
