//------------------------------------------------------------------------------
//  File:          PlacementPopupInputMapper.swift
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

struct PlacementPopupInputMapper {
    func map(
        _ model: PopupPlacementModel,
        overlayType: PlacementOverlayType,
        style: PopUpStyling? = nil,
        loadFollowUp: (@MainActor @Sendable (String?) async throws -> PopupPlacementModel?)?
    ) -> PopupInput {
        let showsCloseButton = model.location != "RTPS-Approval"

        switch overlayType {
        case .embeddedOverlay:
            return .embedded(
                style: style,
                logoURL: model.brandLogoUrl,
                webViewURL: model.webViewUrl,
                showsCloseButton: showsCloseButton
            )

        case .singleProductOverlay:
            let loadActionContent: (@MainActor @Sendable (String?) async throws -> PopupInput.Embedded?)?
            if let loadFollowUp {
                loadActionContent = { placementID in
                    guard let model = try await loadFollowUp(placementID) else { return nil }
                    return Self.embedded(from: model)
                }
            } else {
                loadActionContent = nil
            }
            return .product(
                style: style,
                logoURL: model.brandLogoUrl,
                title: model.overlayTitle,
                subtitle: model.overlaySubtitle,
                header: model.overlayContainerBarHeading,
                sections: bodySections(from: model),
                disclosure: model.disclosure,
                disclosureHTML: model.disclosureHTML,
                actionTitle: model.primaryActionButtonAttributes?.buttonText ?? "Action",
                showsCloseButton: showsCloseButton,
                actionPlacementID: model.primaryActionButtonAttributes?.dataContentFetch,
                loadActionContent: loadActionContent
            )
        }
    }

    private static func embedded(from model: PopupPlacementModel) -> PopupInput.Embedded {
        PopupInput.Embedded(
            logoURL: model.brandLogoUrl,
            webViewURL: model.webViewUrl,
            showsCloseButton: model.location != "RTPS-Approval"
        )
    }

    private func bodySections(from model: PopupPlacementModel) -> [PopupBodySection] {
        let tags = ["h3", "h2", "p", "connector"]
        return model.dynamicBodyModel.bodyDiv
            .sorted { number(in: $0.key) < number(in: $1.key) }
            .flatMap { _, body in
                tags.compactMap { tag in
                    body.tagValuePairs[tag].map { PopupBodySection(tag: tag, text: $0) }
                }
            }
    }

    private func number(in key: String) -> Int {
        Int(key.replacingOccurrences(of: "div", with: "")) ?? 0
    }
}
