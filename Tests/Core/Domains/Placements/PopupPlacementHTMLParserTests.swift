//------------------------------------------------------------------------------
//  File:          PopupPlacementHTMLParserTests.swift
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
import Testing

@Suite
struct PopupPlacementHTMLParserTests {
    private let parser = PopupPlacementHTMLParser()

    @Test
    func extractsSelectedHTMLAndPrimaryActionAttributes() throws {
        let html = """
            <div data-overlay-metadata data-overlay-type="EMBEDDED_OVERLAY"></div>
            <div class="brand logo"><img src="https://images.test/logo.png"></div>
            <iframe src="https://embedded.test"></iframe>
            <div class="epjs-css-overlay-title"><strong>Title</strong></div>
            <div class="epjs-css-overlay-subtitle"><em>Subtitle</em></div>
            <div class="epjs-css-overlay-body-title-bar"><h2>Heading</h2></div>
            <div class="epjs-css-overlay-header"><p>Header</p></div>
            <div class="epjs-css-overlay-disclosures"><p>Disclosure</p></div>
            <div class="epjs-css-modal-footer" data-overlay-type="SINGLE_PRODUCT_OVERLAY"></div>
            <button class="action-button" data-content-fetch="fetch-id" data-action-target="target"
                data-action-type="SHOW_OVERLAY" data-action-content-id="popup-id" data-location="checkout">
                <span>Apply now</span>
            </button>
            """

        let model = try parser.extract(htmlContent: html)

        #expect(model.overlayType == "EMBEDDED_OVERLAY")
        #expect(model.brandLogoURL == "https://images.test/logo.png")
        #expect(model.webViewURL == "https://embedded.test")
        #expect(model.overlayTitleHTML == "<strong>Title</strong>")
        #expect(model.overlaySubtitleHTML == "<em>Subtitle</em>")
        #expect(model.overlayContainerBarHeadingHTML == "<h2>Heading</h2>")
        #expect(model.bodyHeaderHTML == "<p>Header</p>")
        #expect(model.disclosureHTML == "<p>Disclosure</p>")

        let button = try #require(model.primaryActionButtonAttributes)
        #expect(button.dataOverlayType == "SINGLE_PRODUCT_OVERLAY")
        #expect(button.dataContentFetch == "fetch-id")
        #expect(button.dataActionTarget == "target")
        #expect(button.dataActionType == "SHOW_OVERLAY")
        #expect(button.dataActionContentId == "popup-id")
        #expect(button.dataLocation == "checkout")
        #expect(button.buttonText == "Apply now")
    }

    @Test
    func missingSectionsProduceEmptyHTMLAndEmptyBody() throws {
        let model = try parser.extract(htmlContent: "<div>unrelated</div>")

        #expect(model.overlayType == "")
        #expect(model.brandLogoURL == "")
        #expect(model.webViewURL == "")
        #expect(model.overlayTitleHTML == "")
        #expect(model.overlaySubtitleHTML == "")
        #expect(model.overlayContainerBarHeadingHTML == "")
        #expect(model.bodyHeaderHTML == "")
        #expect(model.disclosureHTML == "")
        #expect(model.primaryActionButtonAttributes == nil)
        #expect(model.dynamicBodyModel.bodyDiv.isEmpty)
    }

    @Test
    func emptyHTMLReturnsEmptyStringFallbacks() throws {
        let model = try parser.extract(htmlContent: "")

        #expect(model.overlayType == "")
        #expect(model.brandLogoURL == "")
        #expect(model.webViewURL == "")
        #expect(model.overlayTitleHTML == "")
        #expect(model.overlaySubtitleHTML == "")
        #expect(model.overlayContainerBarHeadingHTML == "")
        #expect(model.bodyHeaderHTML == "")
        #expect(model.disclosureHTML == "")
        #expect(model.primaryActionButtonAttributes == nil)
        #expect(model.dynamicBodyModel.bodyDiv.isEmpty)
    }

    @Test
    func bodyKeysPreserveDirectChildOrdering() throws {
        let html = """
            <div class="epjs-css-overlay-body-content">
              <section><div class="epjs-css-overlay-value-prop"><h3>First</h3></div></section>
              <section><div class="epjs-css-overlay-value-prop-connector">+</div></section>
              <section><div class="epjs-css-overlay-body-footer"><p>Footer</p></div></section>
            </div>
            """

        let body = try parser.extract(htmlContent: html).dynamicBodyModel.bodyDiv

        #expect(body["div0"]?.tagValuePairs == ["h3": "First"])
        #expect(body["div1"]?.tagValuePairs == ["connector": "+"])
        #expect(body["footer2"]?.tagValuePairs == ["p": "Footer"])
    }

    @Test
    func laterMatchesOverwriteDuplicateBodyKeys() throws {
        let html = """
            <div class="epjs-css-overlay-body-content">
              <section>
                <div class="epjs-css-overlay-value-prop"><h3>First</h3></div>
                <div class="epjs-css-overlay-value-prop"><h3>Last value</h3></div>
                <div class="epjs-css-overlay-value-prop-connector">First connector</div>
                <div class="epjs-css-overlay-value-prop-connector">Last connector</div>
                <div class="epjs-css-overlay-body-footer"><p>First footer</p></div>
                <div class="epjs-css-overlay-body-footer"><p>Last footer</p></div>
              </section>
            </div>
            """

        let body = try parser.extract(htmlContent: html).dynamicBodyModel.bodyDiv

        #expect(
            body["div0"]?.tagValuePairs == [
                "connector": "Last connector"
            ])
        #expect(body["footer0"]?.tagValuePairs == ["p": "Last footer"])
        #expect(body.count == 2)
    }
}
