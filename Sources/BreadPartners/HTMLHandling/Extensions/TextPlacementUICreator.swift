//------------------------------------------------------------------------------
//  File:          TextPlacementUICreator.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartnersSDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

import SwiftUI

extension HTMLContentRenderer {

    /// Creates an attributed string that combines normal text and a clickable link.
    func createSpannableText(
        text: String,
        linkText: String
    ) -> NSAttributedString {

        let clickableAttributes: [NSAttributedString.Key: Any] = [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .link: linkText,
        ]

        let normalText = NSAttributedString(
            string: text)
        let clickableText = NSAttributedString(
            string: linkText, attributes: clickableAttributes)

        let combinedText = NSMutableAttributedString()
        combinedText.append(normalText)
        combinedText.append(clickableText)

        return combinedText
    }

    /// Creates a plain, non-editable text view displaying content text.
    func createPlainTextView() -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.text = textPlacementModel?.contentText ?? "N/A"
        return textView
    }

    /// Creates a styled action button with a specified action link.
    func createActionButton() -> UIButton {
        var contentText = textPlacementModel?.contentText ?? ""
        var actionLink = textPlacementModel?.actionLink ?? ""
        let actionType = textPlacementModel?.actionType
        if actionLink.isEmpty {
            actionLink = contentText
            contentText = ""
        }

        let button = UIButton(type: .system)
        button.setTitle(actionLink, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitleColor(UIColor.white, for: .normal)
        button.accessibilityIdentifier = actionLink
        button.backgroundColor = UIColor.blue

        button.layer.masksToBounds = true
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        button.setContentCompressionResistancePriority(
            .defaultHigh, for: .horizontal)
        button.addTarget(
            self, action: #selector(handleButtonTap(_:)), for: .touchUpInside
        )
        return button
    }

    /// Creates a SwiftUI-based plain text view displaying content text.
    func createSwiftUIPlainTextView() -> BreadPartnerTextView {
        return BreadPartnerTextView(textPlacementModel?.contentText ?? "N/A")
    }

    /// Creates a SwiftUI action button with a specified action link.
    func createSwiftUIActionButton() -> BreadPartnerButtonView {
        var contentText = textPlacementModel?.contentText ?? ""
        var actionLink = textPlacementModel?.actionLink ?? ""
        let actionType = textPlacementModel?.actionType

        if actionLink.isEmpty {
            actionLink = contentText
            contentText = ""
        }

        return BreadPartnerButtonView(
            actionLink,
            action: {
                Task {
                    await self.handleLinkInteraction(link: "")
                }
            }
        )
    }
}
