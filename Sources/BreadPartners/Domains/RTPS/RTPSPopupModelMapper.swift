import Foundation

enum RTPSPopupModelMapperError: Error {
    case missingPlacement
    case missingOverlayContent
}

struct RTPSPopupModelMapper {
    func map(_ response: PlacementsResponse) async throws -> PopupPlacementModel {
        guard let placement = response.placements?.first else {
            throw RTPSPopupModelMapperError.missingPlacement
        }

        guard
            let content = response.placementContent?.first(where: {
                $0.metadata?.templateId?.contains("overlay") == true
            }),
            var model = try await HTMLContentParser().extractPopupPlacementModel(
                from: content.contentData?.htmlContent ?? ""
            )
        else {
            throw RTPSPopupModelMapperError.missingOverlayContent
        }

        model.overlayType = PlacementOverlayType.embeddedOverlay.rawValue
        model.location = placement.renderContext?.LOCATION
        model.webViewUrl = placement.renderContext?.embeddedUrl ?? ""
        return model
    }
}
