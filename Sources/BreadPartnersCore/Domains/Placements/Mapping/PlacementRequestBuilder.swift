//------------------------------------------------------------------------------
//  File:          PlacementRequestBuilder.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Foundation

package struct PlacementRequestBuilder: Sendable {
    private let request: PlacementRequest

    package init(
        integrationKey: String,
        merchantConfiguration: MerchantConfiguration?,
        placementConfig: PlacementData?,
        environment: BreadPartnersEnvironment
    ) {
        let upqMapper = UPQMapper()
        var context = ContextRequestBody(
            ENV: environment.rawValue,
            LOCATION: placementConfig?.locationType?.rawValue,
            PRICE: placementConfig?.order?.totalPrice?.value,
            CARDHOLDER_TIER: merchantConfiguration?.cardholderTier.takeIfNotEmpty(),
            STORE_NUMBER: merchantConfiguration?.storeNumber,
            LOYALTY_ID: merchantConfiguration?.loyaltyID.takeIfNotEmpty(),
            OVERRIDE_KEY: merchantConfiguration?.overrideKey.takeIfNotEmpty(),
            CLIENT_VAR_1: merchantConfiguration?.clientVariable1.takeIfNotEmpty(),
            CLIENT_VAR_2: merchantConfiguration?.clientVariable2.takeIfNotEmpty(),
            CLIENT_VAR_3: merchantConfiguration?.clientVariable3.takeIfNotEmpty(),
            CLIENT_VAR_4: merchantConfiguration?.clientVariable4.takeIfNotEmpty(),
            DEPARTMENT_ID: merchantConfiguration?.departmentId.takeIfNotEmpty(),
            channel: merchantConfiguration?.channel ?? placementConfig?.locationType?.channelCode ?? "X",
            subchannel: merchantConfiguration?.subchannel ?? "X",
            CMP: merchantConfiguration?.campaignID.takeIfNotEmpty(),
            ALLOW_CHECKOUT: placementConfig?.allowCheckout ?? false
        )

        if placementConfig?.allowCheckout == true {
            context.UPQ_CHECKOUT_PARAMS = upqMapper.checkoutQueryParams(
                initialData: upqMapper.mapCheckoutData(
                    placementData: placementConfig,
                    merchantConfiguration: merchantConfiguration
                ),
                clientKey: integrationKey
            ).toQueryString()
        } else {
            context.UPQ_PARAMS = upqMapper.offerQueryParams(
                initialData: upqMapper.mapCommonData(
                    placementData: placementConfig,
                    merchantConfiguration: merchantConfiguration
                ),
                clientKey: integrationKey
            ).toQueryString()
        }

        request = PlacementRequest(
            placements: [PlacementRequestBody(id: placementConfig?.placementId, context: context)],
            brandId: integrationKey
        )
    }

    package func build() -> PlacementRequest {
        request
    }
}
