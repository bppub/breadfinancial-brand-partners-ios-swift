import BreadPartnersCore
import Testing

@Suite
struct TextPlacementHTMLParserTests {
    private let parser = TextPlacementHTMLParser()

    @Test
    func extractsPlacementSelectorsAndPreservesInlineFormatting() throws {
        let html = """
            <div class="ep-text-placement" data-action-type="SHOW_OVERLAY" data-action-target="modal" data-action-content-id="popup">
              <div class="epjs-body">Pay over time <span class="epjs-body-action"><a href="/apply"><strong>Apply now</strong></a></span></div>
              <p>0% APR<sup>†</sup></p>
            </div>
            """

        let model = try parser.extract(htmlContent: html)

        #expect(model.actionType == "SHOW_OVERLAY")
        #expect(model.actionTarget == "modal")
        #expect(model.actionContentId == "popup")
        #expect(model.actionLink == "Apply now")
        #expect(model.contentText == "Pay over time Pay over time  0% APR ")
        #expect(model.htmlContent?.contains("<strong>Apply now</strong>") == true)
        #expect(model.htmlContent?.contains("<sup>†</sup>") == true)
    }

    @Test
    func trimsWhitespaceAndCombinesDistinctPaymentDetails() throws {
        let html = """
            <div class="ep-text-placement">
              <div class="epjs-body">  Offer   details  </div>
              <p>  See   terms  </p>
            </div>
            """

        let model = try parser.extract(htmlContent: html)

        #expect(model.contentText == "Offer details Offer details See terms ")
    }

    @Test
    func usesPaymentDetailsWhenBodyTextIsMissing() throws {
        let model = try parser.extract(
            htmlContent: #"<div class="ep-text-placement"><span>Legal copy</span></div>"#
        )

        #expect(model.contentText == "Legal copy ")
    }

    @Test
    func usesBodyTextWhenPaymentDetailsAreRemovedAsActionLink() throws {
        let model = try parser.extract(
            htmlContent:
                #"<div class="ep-text-placement"><div class="epjs-body">Apply<span class="epjs-body-action"><a>Apply</a></span></div></div>"#
        )

        #expect(model.actionLink == "Apply")
        #expect(model.contentText == "Apply ")
    }

    @Test
    func avoidsDuplicatingIdenticalBodyAndPaymentText() throws {
        let model = try parser.extract(
            htmlContent: #"<div class="ep-text-placement"><div class="epjs-body">Pay over time</div></div>"#
        )

        #expect(model.contentText == "Pay over time ")
    }

    @Test
    func excludesActionLinkAndSuperscriptTextFromPaymentDetails() throws {
        let model = try parser.extract(
            htmlContent:
                #"<div class="ep-text-placement"><div class="epjs-body">Offer</div><span class="epjs-body-action"><a>Learn more</a></span><sup>†</sup> Terms</div>"#
        )

        #expect(model.actionLink == "Learn more")
        #expect(model.contentText == "Offer Offer Terms ")
        #expect(model.htmlContent?.contains("<sup>†</sup>") == true)
    }

    @Test
    func emptyHTMLReturnsModelWithNilFields() throws {
        let model = try parser.extract(htmlContent: "")

        #expect(model.actionType == nil)
        #expect(model.actionTarget == nil)
        #expect(model.contentText == nil)
        #expect(model.actionLink == nil)
        #expect(model.actionContentId == nil)
        #expect(model.htmlContent == nil)
    }
}
