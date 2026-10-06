import Foundation

package enum Analytics {
    package struct PlacementContent: Codable, Sendable {
        package let id: String?
        package let contentType: String?
        package let metadata: MetadataModel?

        package init(id: String?, contentType: String?, metadata: MetadataModel?) {
            self.id = id
            self.contentType = contentType
            self.metadata = metadata
        }
    }

    package struct Placement: Codable, Sendable {
        package let id: String?
        package let placementContentId: String?
        package let overlayContentId: String?

        package init(id: String?, placementContentId: String?, overlayContentId: String?) {
            self.id = id
            self.placementContentId = placementContentId
            self.overlayContentId = overlayContentId
        }
    }

    package struct EventProperties: Codable, Sendable {
        package let placement: Placement?
        package let placementContent: PlacementContent?
        package let metadata: [String: String?]?
        package let actionTarget: String?

        package init(
            placement: Placement?, placementContent: PlacementContent?, metadata: [String: String?]?,
            actionTarget: String?
        ) {
            self.placement = placement
            self.placementContent = placementContent
            self.metadata = metadata
            self.actionTarget = actionTarget
        }
    }

    package struct Props: Codable, Sendable {
        package let eventProperties: EventProperties?
        package let userProperties: [String: String]?

        package init(eventProperties: EventProperties?, userProperties: [String: String]?) {
            self.eventProperties = eventProperties
            self.userProperties = userProperties
        }
    }

    package struct BrowserCtx: Codable, Sendable {
        package let library: Library?
        package let userAgent: String?
        package let page: Page?

        package init(library: Library?, userAgent: String?, page: Page?) {
            self.library = library
            self.userAgent = userAgent
            self.page = page
        }
    }

    package struct Library: Codable, Sendable {
        package let name: String?
        package let version: String?

        package init(name: String?, version: String?) {
            self.name = name
            self.version = version
        }
    }

    package struct Page: Codable, Sendable {
        package let path: String?
        package let url: String?

        package init(path: String?, url: String?) {
            self.path = path
            self.url = url
        }
    }

    package struct TrackingInfo: Codable, Sendable {
        package let userTrackingId: String?
        package let sessionTrackingId: String?

        package init(userTrackingId: String?, sessionTrackingId: String?) {
            self.userTrackingId = userTrackingId
            self.sessionTrackingId = sessionTrackingId
        }
    }

    package struct Context: Codable, Sendable {
        package let timestamp: String?
        package let apiKey: String?
        package let browserCtx: BrowserCtx?
        package let trackingInfo: TrackingInfo?

        package init(timestamp: String?, apiKey: String?, browserCtx: BrowserCtx?, trackingInfo: TrackingInfo?) {
            self.timestamp = timestamp
            self.apiKey = apiKey
            self.browserCtx = browserCtx
            self.trackingInfo = trackingInfo
        }
    }

    package struct Payload: Codable, Sendable {
        package let name: String?
        package let props: Props?
        package let context: Context?

        package init(name: String?, props: Props?, context: Context?) {
            self.name = name
            self.props = props
            self.context = context
        }
    }
}
