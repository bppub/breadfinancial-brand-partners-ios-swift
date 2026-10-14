//------------------------------------------------------------------------------
//  File:          PopupPlacementHTMLParser.swift
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
import SwiftSoup

package struct PopupPlacementHTMLParser: Sendable {
    package init() {}

    package func extract(htmlContent: String) throws -> PopupPlacementHTMLModel {
        let document = try SwiftSoup.parse(htmlContent)

        let overlayType =
            try document.select("[data-overlay-metadata]").first()?.attr(
                "data-overlay-type") ?? ""
        let brandLogoURL = try document.select(".brand.logo img").first()?.attr("src") ?? ""
        let webViewURL = try document.select("iframe").first()?.attr("src") ?? ""
        let overlayTitleHTML = (try? document.select(".epjs-css-overlay-title").html()) ?? ""
        let overlaySubtitleHTML = (try? document.select(".epjs-css-overlay-subtitle").html()) ?? ""
        let overlayContainerBarHeadingHTML =
            (try? document.select(".epjs-css-overlay-body-title-bar").html()) ?? ""
        let bodyHeaderHTML = (try? document.select(".epjs-css-overlay-header").html()) ?? ""
        let disclosureHTML = (try? document.select(".epjs-css-overlay-disclosures").html()) ?? ""

        let primaryActionButtonAttributes = try extractPrimaryActionButton(from: document)
        let dynamicBodyModel = try extractDynamicBody(from: document)

        return PopupPlacementHTMLModel(
            overlayType: overlayType,
            brandLogoURL: brandLogoURL,
            webViewURL: webViewURL,
            overlayTitleHTML: overlayTitleHTML,
            overlaySubtitleHTML: overlaySubtitleHTML,
            overlayContainerBarHeadingHTML: overlayContainerBarHeadingHTML,
            bodyHeaderHTML: bodyHeaderHTML,
            primaryActionButtonAttributes: primaryActionButtonAttributes,
            dynamicBodyModel: dynamicBodyModel,
            disclosureHTML: disclosureHTML
        )
    }

    private func extractPrimaryActionButton(from document: Document) throws
        -> PopupPlacementHTMLModel.PrimaryActionButton?
    {
        guard let button = try? document.select(".action-button").first() else {
            return nil
        }

        return PopupPlacementHTMLModel.PrimaryActionButton(
            dataOverlayType: try? document.select(".epjs-css-modal-footer")
                .first()?.attr("data-overlay-type"),
            dataContentFetch: try? button.attr("data-content-fetch"),
            dataActionTarget: try? button.attr("data-action-target"),
            dataActionType: try? button.attr("data-action-type"),
            dataActionContentId: try? button.attr("data-action-content-id"),
            dataLocation: try? button.attr("data-location"),
            buttonText: try? button.select("span").text()
        )
    }

    private func extractDynamicBody(from document: Document) throws
        -> PopupPlacementHTMLModel.DynamicBody
    {
        var bodyDiv: [String: PopupPlacementHTMLModel.DynamicBodyContent] = [:]
        guard let bodyContainer = try document.select(".epjs-css-overlay-body-content").first() else {
            return PopupPlacementHTMLModel.DynamicBody(bodyDiv: bodyDiv)
        }

        var sequenceCounter = 0
        try bodyContainer.children().forEach { mainParent in
            let valueProps = try mainParent.select(".epjs-css-overlay-value-prop")
            for valueProp in valueProps.array() {
                let content = PopupPlacementHTMLModel.DynamicBodyContent(
                    tagValuePairs: try valueProp.children().reduce(into: [:]) { values, child in
                        values[child.tagName()] = try child.html()
                    }
                )
                bodyDiv["div\(sequenceCounter)"] = content
            }

            let connectors = try mainParent.select(".epjs-css-overlay-value-prop-connector")
            for connector in connectors.array() {
                bodyDiv["div\(sequenceCounter)"] = PopupPlacementHTMLModel.DynamicBodyContent(
                    tagValuePairs: ["connector": try connector.html()]
                )
            }

            let footers = try mainParent.select(".epjs-css-overlay-body-footer")
            for footer in footers.array() {
                bodyDiv["footer\(sequenceCounter)"] = PopupPlacementHTMLModel.DynamicBodyContent(
                    tagValuePairs: try footer.children().reduce(into: [:]) { values, child in
                        values[child.tagName()] = try child.html()
                    }
                )
            }
            sequenceCounter += 1
        }

        return PopupPlacementHTMLModel.DynamicBody(bodyDiv: bodyDiv)
    }
}

package struct PopupPlacementHTMLModel: Sendable {
    package let overlayType: String
    package let brandLogoURL: String
    package let webViewURL: String
    package let overlayTitleHTML: String
    package let overlaySubtitleHTML: String
    package let overlayContainerBarHeadingHTML: String
    package let bodyHeaderHTML: String
    package let primaryActionButtonAttributes: PrimaryActionButton?
    package let dynamicBodyModel: DynamicBody
    package let disclosureHTML: String

    package struct PrimaryActionButton: Sendable {
        package let dataOverlayType: String?
        package let dataContentFetch: String?
        package let dataActionTarget: String?
        package let dataActionType: String?
        package let dataActionContentId: String?
        package let dataLocation: String?
        package let buttonText: String?

        package init(
            dataOverlayType: String?,
            dataContentFetch: String?,
            dataActionTarget: String?,
            dataActionType: String?,
            dataActionContentId: String?,
            dataLocation: String?,
            buttonText: String?
        ) {
            self.dataOverlayType = dataOverlayType
            self.dataContentFetch = dataContentFetch
            self.dataActionTarget = dataActionTarget
            self.dataActionType = dataActionType
            self.dataActionContentId = dataActionContentId
            self.dataLocation = dataLocation
            self.buttonText = buttonText
        }
    }

    package struct DynamicBody: Sendable {
        package let bodyDiv: [String: DynamicBodyContent]
    }

    package struct DynamicBodyContent: Sendable {
        package let tagValuePairs: [String: String]
    }
}
