import Foundation

internal enum WebURLBuilder {
    static func buildRTPSWebURL(
        integrationKey: String,
        merchantConfiguration: MerchantConfiguration,
        rtpsData: RTPSData,
        prescreenId: Int64?
    ) -> URL? {
        let mockResponseValue = rtpsData.mockResponse?.rawValue
        var queryParams: [String: String?] = [
            "mockMO": mockResponseValue.takeIfNotEmpty(),
            "mockPA": mockResponseValue.takeIfNotEmpty(),
            "mockVL": mockResponseValue.takeIfNotEmpty(),
            "embedded": "true",
            "clientKey": integrationKey,
            "cardType": rtpsData.cardType,
            "urlPath": "screen name",
            "firstName": merchantConfiguration.buyer?.givenName,
            "lastName": merchantConfiguration.buyer?.familyName,
            "address1": merchantConfiguration.buyer?.billingAddress?.address1,
            "city": merchantConfiguration.buyer?.billingAddress?.locality,
            "state": merchantConfiguration.buyer?.billingAddress?.region,
            "zip": merchantConfiguration.buyer?.billingAddress?.postalCode,
            "storeNumber": merchantConfiguration.storeNumber,
            "location": rtpsData.locationType?.rawValue,
            "channel": rtpsData.channel,
            "mobilePhone": merchantConfiguration.buyer?.phone,
            "emailAddress": merchantConfiguration.buyer?.email,
            "alternativePhone": merchantConfiguration.buyer?.alternativePhone,
        ]

        if let prescreenId {
            queryParams["prescreenId"] = String(prescreenId)
        }

        guard
            var components = URLComponents(
                string: APIUrl(urlType: .rtpsWebUrl(type: "offer")).url
            )
        else {
            return nil
        }
        components.queryItems = queryParams.compactMap { key, value in
            guard let value, !value.isEmpty else { return nil }
            return URLQueryItem(name: key, value: value)
        }
        return components.url
    }

    static func buildBPSWebURL(
        integrationKey: String,
        merchantConfiguration: MerchantConfiguration,
        placementConfiguration: PlacementConfiguration
    ) -> URL? {
        let rtpsData = placementConfiguration.rtpsData
        let placementData = placementConfiguration.placementData
        let buyer = merchantConfiguration.buyer
        let billingAddress = buyer?.billingAddress
        let order = rtpsData?.order ?? placementData?.order
        let location = rtpsData?.locationType?.rawValue ?? placementData?.locationType?.rawValue
        let channel = rtpsData?.channel ?? merchantConfiguration.channel
        let subchannel = rtpsData?.subChannel ?? merchantConfiguration.subchannel
        let mockResponseValue = rtpsData?.mockResponse?.rawValue

        let queryParams: [String: String?] = [
            "mockMO": mockResponseValue.takeIfNotEmpty(),
            "mockPA": mockResponseValue.takeIfNotEmpty(),
            "mockVL": mockResponseValue.takeIfNotEmpty(),
            "embedded": "true",
            "clientKey": integrationKey,
            "prescreenId": rtpsData?.prescreenId.map(String.init),
            "firstName": buyer?.givenName,
            "middleInitial": buyer?.additionalName,
            "lastName": buyer?.familyName,
            "address1": billingAddress?.address1,
            "address2": billingAddress?.address2,
            "city": billingAddress?.locality,
            "state": billingAddress?.region,
            "zip": billingAddress?.postalCode,
            "emailAddress": buyer?.email,
            "mobilePhone": buyer?.phone,
            "alternativePhone": buyer?.alternativePhone,
            "cardType": rtpsData?.cardType,
            "storeNumber": merchantConfiguration.storeNumber,
            "loyaltyNumber": merchantConfiguration.loyaltyID,
            "customerNumber": nil,
            "cartAmount": order?.subTotal?.value.map(String.init),
            "productAmount": order?.items?.first?.unitPrice?.value.map(String.init),
            "checkoutAmount": order?.totalPrice?.value.map(String.init),
            "urlPath": nil,
            "location": location,
            "category": order?.items?.first?.category,
            "sku": order?.items?.first?.sku,
            "correlationData": rtpsData?.correlationData,
            "epId": nil,
            "epPlacementId": nil,
            "epSessionId": nil,
            "epMessageId": nil,
            "channel": channel,
            "subchannel": subchannel,
            "clientVariable1": merchantConfiguration.clientVariable1,
            "clientVariable2": merchantConfiguration.clientVariable2,
            "clientVariable3": merchantConfiguration.clientVariable3,
            "clientVariable4": merchantConfiguration.clientVariable4,
            "selectedCardKey": placementData?.selectedCardKey,
            "defaultSelectedCardKey": placementData?.defaultSelectedCardKey,
            "departmentId": merchantConfiguration.departmentId,
            "overrideKey": merchantConfiguration.overrideKey,
            "cardChoiceCode": nil,
            "associateId": merchantConfiguration.clerkId,
            "carrier": nil,
            "keyword": nil,
            "shortCode": nil,
            "channelId": nil,
            "applicationSubType": nil,
            "splitPayment": nil,
        ]

        guard
            var components = URLComponents(
                string: APIUrl(urlType: .bpsWebUrl).url
            )
        else {
            return nil
        }
        components.queryItems = queryParams.compactMap { key, value in
            guard let value, !value.isEmpty else { return nil }
            return URLQueryItem(name: key, value: value)
        }
        return components.url
    }
}
