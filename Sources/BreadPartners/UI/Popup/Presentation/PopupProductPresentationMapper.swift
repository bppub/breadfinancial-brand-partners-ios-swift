//------------------------------------------------------------------------------
//  File:          PopupProductPresentationMapper.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import SwiftSoup
import UIKit

internal struct PopupProductPresentationModel {
    struct Section {
        let text: NSAttributedString
    }

    let style: PopUpStyling
    let title: NSAttributedString
    let subtitle: NSAttributedString
    let header: NSAttributedString
    let sections: [Section]
    let showsDetailsCard: Bool
    let disclosure: NSAttributedString
    let actionTitle: String
}

@MainActor
internal struct PopupProductPresentationMapper {
    func map(
        product: PopupInput.Product,
        style: PopUpStyling
    ) -> PopupProductPresentationModel {
        PopupProductPresentationModel(
            style: style,
            title: styledText(product.title, style: style.titlePopupTextStyle, alignment: .center),
            subtitle: styledText(product.subtitle, style: style.subTitlePopupTextStyle, alignment: .center),
            header: styledText(product.header, style: style.headerPopupTextStyle, alignment: .center),
            sections: product.sections.compactMap { section in
                guard let textStyle = sectionStyle(for: section.tag, style: style) else {
                    return nil
                }
                return PopupProductPresentationModel.Section(
                    text: styledText(section.text.toAttributedString(), style: textStyle, alignment: .center)
                )
            },
            showsDetailsCard: !product.sections.isEmpty,
            disclosure: disclosureText(
                product.disclosure, html: product.disclosureHTML, style: style.disclosurePopupTextStyle),
            actionTitle: product.actionTitle
        )
    }

    private func sectionStyle(
        for tag: String,
        style: PopUpStyling
    ) -> PopupTextStyle? {
        switch tag.lowercased() {
        case "h3":
            return style.headingThreePopupTextStyle
        case "p", "footer":
            return style.paragraphPopupTextStyle
        case "connector":
            return style.connectorPopupTextStyle
        default:
            return nil
        }
    }

    private func disclosureText(
        _ text: NSAttributedString,
        html: String,
        style: PopupTextStyle
    ) -> NSAttributedString {
        let styled = NSMutableAttributedString(
            attributedString: styledText(text, style: style)
        )
        let source = styled.string as NSString
        guard let document = try? SwiftSoup.parse(html), source.length > 0 else {
            return styled
        }

        let anchors = (try? document.select("a[href]").array()) ?? []
        for anchor in anchors {
            guard
                let href = try? anchor.attr("href"),
                !href.isEmpty,
                let url = URL(string: href),
                let linkText = try? anchor.text(),
                !linkText.isEmpty
            else { continue }

            let range = source.range(of: linkText)
            guard range.location != NSNotFound else { continue }
            styled.addAttribute(.link, value: url, range: range)
        }
        return styled
    }

    private func styledText(
        _ text: NSAttributedString,
        style: PopupTextStyle,
        alignment: NSTextAlignment? = nil
    ) -> NSAttributedString {
        guard text.length > 0 else { return text }

        let mutable = NSMutableAttributedString(attributedString: text)
        let fullRange = NSRange(location: 0, length: mutable.length)
        mutable.addAttribute(.foregroundColor, value: style.textColor, range: fullRange)

        guard let targetFont = style.font else { return mutable }
        applyFont(targetFont, to: mutable, in: fullRange)
        if let alignment {
            mutable.enumerateAttribute(.paragraphStyle, in: fullRange, options: []) { value, range, _ in
                let paragraph =
                    ((value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle)
                    ?? NSMutableParagraphStyle()
                paragraph.alignment = alignment
                mutable.addAttribute(.paragraphStyle, value: paragraph, range: range)
            }
        }
        return mutable
    }

    private func applyFont(
        _ targetFont: UIFont,
        to mutable: NSMutableAttributedString,
        in range: NSRange
    ) {
        mutable.enumerateAttribute(.font, in: range, options: []) { value, range, _ in
            let newFont: UIFont
            if let existingFont = value as? UIFont {
                let traits = targetFont.fontDescriptor.symbolicTraits
                    .union(existingFont.fontDescriptor.symbolicTraits)
                let descriptor = targetFont.fontDescriptor
                    .withFamily(targetFont.familyName)
                    .withSymbolicTraits(traits)
                newFont = resolvedFont(targetFont: targetFont, descriptor: descriptor)
            } else {
                newFont = targetFont
            }
            mutable.addAttribute(.font, value: newFont, range: range)
        }
    }

    func resolvedFont(targetFont: UIFont, descriptor: UIFontDescriptor?) -> UIFont {
        guard let descriptor else { return targetFont }
        return UIFont(
            descriptor: descriptor.withSize(targetFont.pointSize),
            size: targetFont.pointSize
        )
    }
}
