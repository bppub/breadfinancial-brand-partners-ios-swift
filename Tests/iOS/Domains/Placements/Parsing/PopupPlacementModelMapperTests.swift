//------------------------------------------------------------------------------
//  File:          PopupPlacementModelMapperTests.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import BreadPartnersCore
import Foundation
import Testing
import UIKit

@testable import BreadPartners

@Suite
struct PopupPlacementModelMapperTests {
    @Test
    func mapsHTMLTextToAttributedUIModelPreservingFormatting() throws {
        let parsed = try PopupPlacementHTMLParser().extract(
            htmlContent: "<div class=\"epjs-css-overlay-title\"><strong>Special offer</strong></div>"
        )
        let model = PopupPlacementModelMapper().map(parsed)

        #expect(model.overlayTitle.string == "Special offer")

        let boldRange = (model.overlayTitle.string as NSString).range(of: "Special offer")
        let font =
            model.overlayTitle.attribute(.font, at: boldRange.location, effectiveRange: nil)
            as? UIFont
        #expect(font?.fontDescriptor.symbolicTraits.contains(.traitBold) == true)
    }

    @Test
    func mapsAllParsedPopupContentIntoUIModel() throws {
        let parsed = try PopupPlacementHTMLParser().extract(
            htmlContent: """
                <div data-overlay-metadata data-overlay-type="SINGLE_PRODUCT_OVERLAY"></div>
                <div class="brand logo"><img src="https://brand.test/logo.svg"></div>
                <iframe src="https://content.test"></iframe>
                <div class="epjs-css-overlay-title">Title</div>
                <div class="epjs-css-overlay-subtitle">Subtitle</div>
                <div class="epjs-css-overlay-body-title-bar">Heading</div>
                <div class="epjs-css-overlay-header">Body header</div>
                <div class="epjs-css-modal-footer" data-overlay-type="EMBEDDED_OVERLAY">
                    <button class="action-button" data-content-fetch="content-fetch"
                        data-action-target="target" data-action-type="SHOW_OVERLAY"
                        data-action-content-id="content-id" data-location="popup">
                        <span>Continue</span>
                    </button>
                </div>
                <div class="epjs-css-overlay-body-content">
                    <div>
                        <div class="epjs-css-overlay-value-prop">
                            <span>2.9%</span><p>APR</p>
                        </div>
                    </div>
                    <div>
                        <div class="epjs-css-overlay-value-prop-connector">plus</div>
                    </div>
                    <div>
                        <div class="epjs-css-overlay-body-footer">
                            <strong>Terms</strong><span>apply</span>
                        </div>
                    </div>
                </div>
                <div class="epjs-css-overlay-disclosures">See <em>terms</em></div>
                """
        )
        let model = PopupPlacementModelMapper().map(parsed)

        #expect(model.overlayType == "SINGLE_PRODUCT_OVERLAY")
        #expect(model.brandLogoUrl == "https://brand.test/logo.svg")
        #expect(model.webViewUrl == "https://content.test")
        #expect(model.overlayTitle.string == "Title")
        #expect(model.overlaySubtitle.string == "Subtitle")
        #expect(model.overlayContainerBarHeading.string == "Heading")
        #expect(model.bodyHeader.string == "Body header")
        #expect(model.disclosure.string == "See terms")
        #expect(model.disclosureHTML.hasPrefix("See"))
        #expect(model.disclosureHTML.contains("<em>terms</em>"))

        let button = try #require(model.primaryActionButtonAttributes)
        #expect(button.dataOverlayType == "EMBEDDED_OVERLAY")
        #expect(button.dataContentFetch == "content-fetch")
        #expect(button.dataActionTarget == "target")
        #expect(button.dataActionType == "SHOW_OVERLAY")
        #expect(button.dataActionContentId == "content-id")
        #expect(button.dataLocation == "popup")
        #expect(button.buttonText == "Continue")

        #expect(
            model.dynamicBodyModel.bodyDiv["div0"]?.tagValuePairs == [
                "span": "2.9%",
                "p": "APR",
            ])
        #expect(
            model.dynamicBodyModel.bodyDiv["div1"]?.tagValuePairs == [
                "connector": "plus"
            ])
        #expect(
            model.dynamicBodyModel.bodyDiv["footer2"]?.tagValuePairs == [
                "strong": "Terms",
                "span": "apply",
            ])
    }

    @Test
    func mapsMissingHTMLFieldsToEmptyAttributedValues() throws {
        let parsed = try PopupPlacementHTMLParser().extract(htmlContent: "<html></html>")
        let model = PopupPlacementModelMapper().map(parsed)

        #expect(model.overlayTitle.string.isEmpty)
        #expect(model.overlaySubtitle.string.isEmpty)
        #expect(model.overlayContainerBarHeading.string.isEmpty)
        #expect(model.bodyHeader.string.isEmpty)
        #expect(model.disclosure.string.isEmpty)
        #expect(model.disclosureHTML.isEmpty)
    }
}
