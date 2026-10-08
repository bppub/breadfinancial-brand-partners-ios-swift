import Foundation
import SwiftSoup

package struct TextPlacementHTMLParser: Sendable {
    package init() {}

    package func extract(htmlContent: String) throws -> TextPlacementModel {
        let document = try SwiftSoup.parse(htmlContent)

        let actionContentId = try document.select("[data-action-content-id]")
            .attr("data-action-content-id")
        let actionTarget = try document.select("[data-action-target]").attr(
            "data-action-target")
        let actionType = try document.select("[data-action-type]").attr(
            "data-action-type")

        let htmlContentWithFormatting = try document.select(".ep-text-placement").html()
        let actionLink = try document.select(".epjs-body-action a").text()
        let contentText =
            try document.select(".epjs-body").first()?.ownText()
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let paymentDetailsSup = try document.select("sup").text()

        var paymentDetails = try document.select(".ep-text-placement").text()
        paymentDetails =
            paymentDetails
            .replacingOccurrences(of: actionLink, with: "")
            .replacingOccurrences(of: paymentDetailsSup, with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let finalContentText: String = {
            switch (contentText.isEmpty, paymentDetails.isEmpty) {
            case (true, true): return ""
            case (true, false): return paymentDetails + " "
            case (false, true): return contentText + " "
            default:
                return contentText == paymentDetails
                    ? contentText + " "
                    : contentText + " " + paymentDetails + " "
            }
        }()

        return TextPlacementModel(
            actionType: actionType.isEmpty ? nil : actionType,
            actionTarget: actionTarget.isEmpty ? nil : actionTarget,
            contentText: finalContentText.isEmpty ? nil : finalContentText,
            actionLink: actionLink.isEmpty ? nil : actionLink,
            actionContentId: actionContentId.isEmpty ? nil : actionContentId,
            htmlContent: htmlContentWithFormatting.isEmpty ? nil : htmlContentWithFormatting
        )
    }
}
