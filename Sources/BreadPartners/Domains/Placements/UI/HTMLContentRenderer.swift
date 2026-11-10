//------------------------------------------------------------------------------
//  File:          HTMLContentRenderer.swift
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
import SwiftUI
import UIKit

private struct TextPlacementRenderContext {
    let responseModel: PlacementsResponse
    let textPlacementModel: TextPlacementModel
}

/// Renders parsed HTML content into native UI elements.
@MainActor
internal class HTMLContentRenderer {

    let splitTextAndAction: Bool
    let forSwiftUI: Bool
    let logger: Logger
    let analyticsReporter: any AnalyticsReporting
    let callback: (BreadPartnerEvents) -> Void
    let onShowOverlay: @MainActor (PlacementsResponse, TextPlacementModel) async -> Void
    private let actionTypeResolver: @MainActor (String) async -> PlacementActionType?
    private let textPlacementParser: (String) throws -> TextPlacementModel
    private let htmlToAttributedString: (String) -> NSAttributedString?

    init(
        splitTextAndAction: Bool = false,
        forSwiftUI: Bool = false,
        logger: Logger,
        analyticsReporter: any AnalyticsReporting,
        callback: @escaping ((BreadPartnerEvents) -> Void),
        onShowOverlay: @escaping @MainActor (PlacementsResponse, TextPlacementModel) async -> Void,
        actionTypeResolver: @escaping @MainActor (String) async -> PlacementActionType? = { actionType in
            await HTMLContentParser().handleActionType(from: actionType)
        },
        htmlToAttributedString: @escaping (String) -> NSAttributedString? = { $0.htmlToAttributedString() },
        textPlacementParser: @escaping (String) throws -> TextPlacementModel = { htmlContent in
            try TextPlacementHTMLParser().extract(htmlContent: htmlContent)
        }
    ) {
        self.splitTextAndAction = splitTextAndAction
        self.forSwiftUI = forSwiftUI
        self.logger = logger
        self.analyticsReporter = analyticsReporter
        self.callback = callback
        self.onShowOverlay = onShowOverlay
        self.actionTypeResolver = actionTypeResolver
        self.htmlToAttributedString = htmlToAttributedString
        self.textPlacementParser = textPlacementParser
    }

    // MARK: - Placement Handling
    func handleTextPlacement(responseModel: PlacementsResponse) async {
        guard
            let placementContent = responseModel.placementContent?.first?
                .contentData?.htmlContent
        else {
            return callback(
                .sdkError(
                    error: NSError(
                        domain: "", code: 500,
                        userInfo: [
                            NSLocalizedDescriptionKey: Constants
                                .noTextPlacementError
                        ])))
        }

        guard let textPlacementModel = try? textPlacementParser(placementContent) else {
            return callback(
                .sdkError(
                    error: NSError(
                        domain: "", code: 500,
                        userInfo: [
                            NSLocalizedDescriptionKey: Constants
                                .textPlacementParsingError
                        ])))
        }

        logger.logTextPlacementModelDetails(textPlacementModel)

        let context = TextPlacementRenderContext(
            responseModel: responseModel,
            textPlacementModel: textPlacementModel
        )

        Task {
            await analyticsReporter.send(
                event: .viewPlacement,
                placementResponse: responseModel)
        }

        if self.splitTextAndAction {
            renderTextAndButton(context: context)
        } else {
            renderTextViewWithLink(context: context)
        }
    }

    // MARK: - View Rendering
    private func renderTextAndButton(context: TextPlacementRenderContext) {
        let textPlacementModel = context.textPlacementModel
        let contentText = textPlacementModel.contentText ?? ""
        var actionLink = textPlacementModel.actionLink ?? ""
        if actionLink.isEmpty {
            actionLink = contentText
        }

        if forSwiftUI {
            let plainTextView = BreadPartnerTextView(textPlacementModel.contentText ?? "N/A")
            let actionButton = BreadPartnerButtonView(
                actionLink,
                action: {
                    Task { await self.handleLinkInteraction(context: context) }
                })
            callback(.renderSwiftUISeparateTextAndButton(textView: plainTextView, button: actionButton))
        } else {
            let plainTextView = makePlainTextView(contentText: textPlacementModel.contentText ?? "N/A")
            let actionButton = makeActionButton(title: actionLink) {
                Task { await self.handleLinkInteraction(context: context) }
            }
            callback(.renderSeparateTextAndButton(textView: plainTextView, button: actionButton))
        }
    }

    private func renderTextViewWithLink(context: TextPlacementRenderContext) {
        var contentText = context.textPlacementModel.contentText ?? ""
        var actionLink = context.textPlacementModel.actionLink ?? ""
        let actionType = context.textPlacementModel.actionType
        let htmlContent = context.textPlacementModel.htmlContent

        if actionType == PlacementActionType.noAction.rawValue,
            let htmlString = htmlContent,
            !htmlString.isEmpty
        {
            if let attributedString = htmlToAttributedString(htmlString) {
                let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
                let range = NSRange(location: 0, length: mutableAttributedString.length)
                mutableAttributedString.removeAttribute(.link, range: range)
                mutableAttributedString.removeAttribute(.underlineStyle, range: range)

                if forSwiftUI {
                    let swiftUIView = BreadPartnerLinkTextSwitUI(
                        attributedString: mutableAttributedString,
                        onTap: { Task { await self.handleLinkInteraction(context: context) } }
                    )
                    callback(.renderSwiftUITextViewWithLink(textView: swiftUIView))
                } else {
                    let textView = BreadPartnerLinkText()
                    textView.configure(with: mutableAttributedString) { [self] _ in
                        Task { await handleLinkInteraction(context: context) }
                    }
                    callback(.renderTextViewWithLink(textView: textView))
                }
            } else if forSwiftUI {
                let swiftUIView = BreadPartnerLinkTextSwitUI(
                    contentText,
                    links: [],
                    onTap: { Task { await self.handleLinkInteraction(context: context) } }
                )
                callback(.renderSwiftUITextViewWithLink(textView: swiftUIView))
            } else {
                let textView = BreadPartnerLinkText()
                textView.configure(with: NSAttributedString(string: contentText)) { [self] _ in
                    Task { await handleLinkInteraction(context: context) }
                }
                callback(.renderTextViewWithLink(textView: textView))
            }
            return
        }

        if actionLink.isEmpty {
            actionLink = contentText
            contentText = ""
        }

        if forSwiftUI {
            let swiftUIView = BreadPartnerLinkTextSwitUI(
                contentText + actionLink,
                links: [actionLink],
                onTap: { Task { await self.handleLinkInteraction(context: context) } }
            )
            callback(.renderSwiftUITextViewWithLink(textView: swiftUIView))
        } else {
            let textView = BreadPartnerLinkText()
            let combinedText = makeSpannableText(text: contentText, linkText: actionLink)
            textView.linkTextAttributes = [
                .foregroundColor: UIColor.blue,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
            ]
            textView.configure(with: combinedText) { [self] _ in
                Task { await handleLinkInteraction(context: context) }
            }
            callback(.renderTextViewWithLink(textView: textView))
        }
    }

    // MARK: - Placement Interaction
    private func handleLinkInteraction(context: TextPlacementRenderContext) async {
        let placementModel = context.textPlacementModel
        if let actionType = await actionTypeResolver(placementModel.actionType ?? "") {
            switch actionType {
            case .showOverlay:
                await onShowOverlay(context.responseModel, placementModel)
            case .noAction:
                callback(.textClicked)
            default:
                callback(
                    .sdkError(
                        error: NSError(
                            domain: "", code: 500,
                            userInfo: [NSLocalizedDescriptionKey: Constants.missingTextPlacementError]
                        )
                    )
                )
            }
        } else {
            callback(
                .sdkError(
                    error: NSError(
                        domain: "", code: 500,
                        userInfo: [NSLocalizedDescriptionKey: Constants.noTextPlacementError]
                    )
                )
            )
        }
    }

    // MARK: - UIKit Views
    private func makeSpannableText(text: String, linkText: String) -> NSAttributedString {
        let clickableAttributes: [NSAttributedString.Key: Any] = [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .link: linkText,
        ]
        let combinedText = NSMutableAttributedString(string: text)
        combinedText.append(NSAttributedString(string: linkText, attributes: clickableAttributes))
        return combinedText
    }

    private func makePlainTextView(contentText: String) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.text = contentText
        return textView
    }

    private func makeActionButton(title: String, onTap: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitleColor(.white, for: .normal)
        button.accessibilityIdentifier = title
        button.backgroundColor = .blue
        button.layer.masksToBounds = true
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        button.addAction(UIAction { _ in onTap() }, for: .touchUpInside)
        return button
    }

}
