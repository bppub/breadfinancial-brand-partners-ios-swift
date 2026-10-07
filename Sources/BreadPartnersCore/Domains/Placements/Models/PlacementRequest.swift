//------------------------------------------------------------------------------
//  File:          PlacementRequest.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

import Foundation

package struct PlacementRequest: Codable, Sendable {
    package let placements: [PlacementRequestBody]?
    package let brandId: String?

    package init(placements: [PlacementRequestBody]? = nil, brandId: String? = nil) {
        self.placements = placements
        self.brandId = brandId
    }
}

package struct PlacementRequestBody: Codable, Sendable {
    package let id: String?
    package let context: ContextRequestBody?

    package init(id: String? = nil, context: ContextRequestBody? = nil) {
        self.id = id
        self.context = context
    }
}

package struct ContextRequestBody: Codable, Sendable {
    package let SDK_TID: String?
    package let ENV: String?
    package let RTPS_ID: String?
    package let BUYER_ID: String?
    package let PREQUAL_ID: String?
    package let PREQUAL_CREDIT_LIMIT: String?
    package let LOCATION: String?
    package let PRICE: Int64?
    package let EXISTING_CH: Bool?
    package let CARDHOLDER_TIER: String?
    package let STORE_NUMBER: String?
    package let LOYALTY_ID: String?
    package let OVERRIDE_KEY: String?
    package let CLIENT_VAR_1: String?
    package let CLIENT_VAR_2: String?
    package let CLIENT_VAR_3: String?
    package let CLIENT_VAR_4: String?
    package let DEPARTMENT_ID: String?
    package let channel: String?
    package let subchannel: String?
    package let CMP: String?
    package let ALLOW_CHECKOUT: Bool?
    package var UPQ_PARAMS: String?
    package var UPQ_CHECKOUT_PARAMS: String?
    package let embeddedUrl: String?

    package init(
        SDK_TID: String? = nil,
        ENV: String? = nil,
        RTPS_ID: String? = nil,
        BUYER_ID: String? = nil,
        PREQUAL_ID: String? = nil,
        PREQUAL_CREDIT_LIMIT: String? = nil,
        LOCATION: String? = nil,
        PRICE: Int64? = nil,
        EXISTING_CH: Bool? = nil,
        CARDHOLDER_TIER: String? = nil,
        STORE_NUMBER: String? = nil,
        LOYALTY_ID: String? = nil,
        OVERRIDE_KEY: String? = nil,
        CLIENT_VAR_1: String? = nil,
        CLIENT_VAR_2: String? = nil,
        CLIENT_VAR_3: String? = nil,
        CLIENT_VAR_4: String? = nil,
        DEPARTMENT_ID: String? = nil,
        channel: String? = nil,
        subchannel: String? = nil,
        CMP: String? = nil,
        ALLOW_CHECKOUT: Bool? = nil,
        UPQ_PARAMS: String? = nil,
        UPQ_CHECKOUT_PARAMS: String? = nil,
        embeddedUrl: String? = nil
    ) {
        self.SDK_TID = SDK_TID
        self.ENV = ENV
        self.RTPS_ID = RTPS_ID
        self.BUYER_ID = BUYER_ID
        self.PREQUAL_ID = PREQUAL_ID
        self.PREQUAL_CREDIT_LIMIT = PREQUAL_CREDIT_LIMIT
        self.LOCATION = LOCATION
        self.PRICE = PRICE
        self.EXISTING_CH = EXISTING_CH
        self.CARDHOLDER_TIER = CARDHOLDER_TIER
        self.STORE_NUMBER = STORE_NUMBER
        self.LOYALTY_ID = LOYALTY_ID
        self.OVERRIDE_KEY = OVERRIDE_KEY
        self.CLIENT_VAR_1 = CLIENT_VAR_1
        self.CLIENT_VAR_2 = CLIENT_VAR_2
        self.CLIENT_VAR_3 = CLIENT_VAR_3
        self.CLIENT_VAR_4 = CLIENT_VAR_4
        self.DEPARTMENT_ID = DEPARTMENT_ID
        self.channel = channel
        self.subchannel = subchannel
        self.CMP = CMP
        self.ALLOW_CHECKOUT = ALLOW_CHECKOUT
        self.UPQ_PARAMS = UPQ_PARAMS
        self.UPQ_CHECKOUT_PARAMS = UPQ_CHECKOUT_PARAMS
        self.embeddedUrl = embeddedUrl
    }

    package func copy(upqParams: String? = nil, upqCheckoutParams: String? = nil) -> ContextRequestBody {
        ContextRequestBody(
            UPQ_PARAMS: upqParams,
            UPQ_CHECKOUT_PARAMS: upqCheckoutParams
        )
    }
}
