import Foundation

package struct AnalyticsPayloadBuilder: Sendable {
    package init() {}

    package func build(
        name: String,
        placementResponse: PlacementsResponse,
        timestamp: String,
        apiKey: String,
        userAgent: String?
    ) -> Analytics.Payload {
        let placement = placementResponse.placements?.first
        let content = placementResponse.placementContent?.first

        return Analytics.Payload(
            name: name,
            props: Analytics.Props(
                eventProperties: Analytics.EventProperties(
                    placement: Analytics.Placement(
                        id: placement?.id,
                        placementContentId: content?.id,
                        overlayContentId: content?.id
                    ),
                    placementContent: Analytics.PlacementContent(
                        id: content?.id,
                        contentType: content?.contentType,
                        metadata: content?.metadata
                    ),
                    metadata: ["location": placement?.renderContext?.LOCATION],
                    actionTarget: nil
                ),
                userProperties: [:]
            ),
            context: Analytics.Context(
                timestamp: timestamp,
                apiKey: apiKey,
                browserCtx: Analytics.BrowserCtx(
                    library: Analytics.Library(name: "bread-partners-sdk-ios", version: "0.0.1"),
                    userAgent: userAgent,
                    page: Analytics.Page(path: "ToDo", url: nil)
                ),
                trackingInfo: Analytics.TrackingInfo(
                    userTrackingId: placement?.renderContext?.SDK_TID,
                    sessionTrackingId: "ToDO"
                )
            )
        )
    }
}
