//------------------------------------------------------------------------------
//  File:          PlacementResponse.swift
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

package struct PlacementsResponse: Codable, Sendable {
    package let placements: [PlacementsModel]?
    package let placementContent: [PlacementContentModel]?

    package init(placements: [PlacementsModel]?, placementContent: [PlacementContentModel]?) {
        self.placements = placements
        self.placementContent = placementContent
    }
}

package struct PlacementsModel: Codable, Sendable {
    package let id: String?
    package let content: PlacementContentReferenceModel?
    package let renderContext: RenderContextModel?

    package init(id: String?, content: PlacementContentReferenceModel?, renderContext: RenderContextModel?) {
        self.id = id
        self.content = content
        self.renderContext = renderContext
    }
}

package struct PlacementContentReferenceModel: Codable, Sendable {
    package let contentId: String?

    package init(contentId: String?) {
        self.contentId = contentId
    }
}

package struct RenderContextModel: Codable, Sendable {
    package let LOCATION: String?
    package let subchannel: String?
    package let RTPS_ID: String?
    package let PREQUAL_ID: String?
    package let PRICE: Int?
    package let DATETIME: String?
    package let SDK_TID: String?
    package let BUYER_ID: String?
    package let channel: String?
    package let PREQUAL_CREDIT_LIMIT: String?
    package let ENV: String?
    package let ALLOW_CHECKOUT: Bool?
    package let embeddedUrl: String?

    package init(
        LOCATION: String?,
        subchannel: String?,
        RTPS_ID: String?,
        PREQUAL_ID: String?,
        PRICE: Int?,
        DATETIME: String?,
        SDK_TID: String?,
        BUYER_ID: String?,
        channel: String?,
        PREQUAL_CREDIT_LIMIT: String?,
        ENV: String?,
        ALLOW_CHECKOUT: Bool?,
        embeddedUrl: String?
    ) {
        self.LOCATION = LOCATION
        self.subchannel = subchannel
        self.RTPS_ID = RTPS_ID
        self.PREQUAL_ID = PREQUAL_ID
        self.PRICE = PRICE
        self.DATETIME = DATETIME
        self.SDK_TID = SDK_TID
        self.BUYER_ID = BUYER_ID
        self.channel = channel
        self.PREQUAL_CREDIT_LIMIT = PREQUAL_CREDIT_LIMIT
        self.ENV = ENV
        self.ALLOW_CHECKOUT = ALLOW_CHECKOUT
        self.embeddedUrl = embeddedUrl
    }
}

package struct PlacementContentModel: Codable, Sendable {
    package let id: String?
    package let contentType: String?
    package let contentData: ContentDataModel?
    package let metadata: MetadataModel?

    package init(id: String?, contentType: String?, contentData: ContentDataModel?, metadata: MetadataModel?) {
        self.id = id
        self.contentType = contentType
        self.contentData = contentData
        self.metadata = metadata
    }
}

package struct ContentDataModel: Codable, Sendable {
    package let htmlContent: String?

    package init(htmlContent: String?) {
        self.htmlContent = htmlContent
    }
}

package struct MetadataModel: Codable, Sendable {
    package let placementId: String?
    package let productType: String?
    package let messageId: String?
    package let templateId: String?

    package init(placementId: String?, productType: String?, messageId: String?, templateId: String?) {
        self.placementId = placementId
        self.productType = productType
        self.messageId = messageId
        self.templateId = templateId
    }
}
