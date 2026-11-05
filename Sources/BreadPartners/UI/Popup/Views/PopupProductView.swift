//------------------------------------------------------------------------------
//  File:          PopupProductView.swift
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

@MainActor
internal final class PopupProductView: UIView, UITextViewDelegate {
    let scrollView = UIScrollView()
    let titleLabel: UILabel
    let subtitleLabel: UILabel
    let disclosureTextView: UITextView
    let detailsView: UIView
    let headerLabel: UILabel
    let sectionStackView: UIStackView
    let actionButton: UIButton
    let bottomRowView = UIView()

    var onAction: (() -> Void)?

    private let contentView = UIView()
    private let headerView = UIView()
    private let dividerBottom = UIView()
    private let style: PopUpStyling

    init(product: PopupInput.Product, style: PopUpStyling) {
        self.style = style
        titleLabel = Self.makeLabel(
            withText: product.title,
            style: style.titlePopupTextStyle
        )
        subtitleLabel = Self.makeLabel(
            withText: product.subtitle,
            style: style.subTitlePopupTextStyle
        )
        disclosureTextView = Self.makeDisclosureTextView(
            text: product.disclosure,
            rawHTML: product.disclosureHTML,
            style: style.disclosurePopupTextStyle
        )
        detailsView = Self.makeContainerView(
            backgroundColor: style.backgroundColor,
            borderColor: style.borderColor
        )
        headerLabel = Self.makeLabel(
            withText: product.header,
            style: style.headerPopupTextStyle
        )
        sectionStackView = UIStackView()
        actionButton = Self.makeActionButton(
            title: product.actionTitle,
            style: style.actionButtonStyle
        )
        super.init(frame: .zero)

        disclosureTextView.delegate = self
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        configure(product: product)
        installConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        guard URL.absoluteString == "#epjs-css-overlay-header" else { return true }
        scrollView.setContentOffset(.zero, animated: true)
        return false
    }

    @objc private func actionButtonTapped() {
        onAction?()
    }

    private func configure(product: PopupInput.Product) {
        translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        bottomRowView.translatesAutoresizingMaskIntoConstraints = false
        headerView.translatesAutoresizingMaskIntoConstraints = false
        dividerBottom.translatesAutoresizingMaskIntoConstraints = false
        sectionStackView.translatesAutoresizingMaskIntoConstraints = false

        headerView.backgroundColor = style.headerBgColor
        headerView.isHidden = headerLabel.text?.isEmpty ?? true
        detailsView.isHidden = product.sections.isEmpty
        sectionStackView.axis = .vertical
        sectionStackView.spacing = 10
        sectionStackView.alignment = .fill
        dividerBottom.backgroundColor = style.dividerColor

        for section in product.sections {
            guard let label = makeSectionLabel(tag: section.tag, text: section.text) else {
                continue
            }
            sectionStackView.addArrangedSubview(label)
        }

        addSubview(scrollView)
        addSubview(bottomRowView)
        scrollView.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(detailsView)
        contentView.addSubview(disclosureTextView)
        detailsView.addSubview(headerView)
        detailsView.addSubview(sectionStackView)
        headerView.addSubview(headerLabel)
        bottomRowView.addSubview(dividerBottom)
        bottomRowView.addSubview(actionButton)
    }

    private func installConstraints() {
        let horizontalPadding: CGFloat = 20
        let smallPadding: CGFloat = 10
        let verticalPadding: CGFloat = 10

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomRowView.topAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: verticalPadding),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalPadding),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalPadding),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: verticalPadding),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalPadding),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalPadding),

            detailsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalPadding),
            detailsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalPadding),

            disclosureTextView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: horizontalPadding),
            disclosureTextView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -horizontalPadding),
            disclosureTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -verticalPadding),

            bottomRowView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomRowView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomRowView.bottomAnchor.constraint(equalTo: bottomAnchor),

            dividerBottom.topAnchor.constraint(equalTo: bottomRowView.topAnchor),
            dividerBottom.leadingAnchor.constraint(equalTo: bottomRowView.leadingAnchor),
            dividerBottom.trailingAnchor.constraint(equalTo: bottomRowView.trailingAnchor),
            dividerBottom.heightAnchor.constraint(equalToConstant: 1),

            actionButton.topAnchor.constraint(equalTo: dividerBottom.bottomAnchor, constant: verticalPadding),
            actionButton.bottomAnchor.constraint(equalTo: bottomRowView.bottomAnchor, constant: -20),
            actionButton.widthAnchor.constraint(
                greaterThanOrEqualTo: actionButton.titleLabel!.widthAnchor, constant: 50),
            actionButton.heightAnchor.constraint(
                greaterThanOrEqualTo: actionButton.titleLabel!.heightAnchor, constant: 30),
            actionButton.trailingAnchor.constraint(equalTo: bottomRowView.trailingAnchor, constant: -smallPadding),
        ])

        if detailsView.isHidden {
            NSLayoutConstraint.activate([
                detailsView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor),
                detailsView.heightAnchor.constraint(equalToConstant: 0),
                disclosureTextView.topAnchor.constraint(
                    equalTo: subtitleLabel.bottomAnchor,
                    constant: 5
                ),
            ])
        } else {
            NSLayoutConstraint.activate([
                detailsView.topAnchor.constraint(
                    equalTo: subtitleLabel.bottomAnchor,
                    constant: horizontalPadding
                ),
                headerLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
                headerLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                headerLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: smallPadding),
                headerLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -smallPadding),
                headerView.topAnchor.constraint(equalTo: detailsView.topAnchor),
                headerView.leadingAnchor.constraint(equalTo: detailsView.leadingAnchor),
                headerView.trailingAnchor.constraint(equalTo: detailsView.trailingAnchor),
                headerView.heightAnchor.constraint(greaterThanOrEqualTo: headerLabel.heightAnchor, constant: 30),
                sectionStackView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: smallPadding),
                sectionStackView.leadingAnchor.constraint(equalTo: detailsView.leadingAnchor, constant: smallPadding),
                sectionStackView.trailingAnchor.constraint(
                    equalTo: detailsView.trailingAnchor, constant: -smallPadding),
                detailsView.bottomAnchor.constraint(
                    equalTo: sectionStackView.bottomAnchor, constant: horizontalPadding),
                disclosureTextView.topAnchor.constraint(
                    equalTo: detailsView.bottomAnchor,
                    constant: 24
                ),
            ])
        }

        disclosureTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -verticalPadding)
            .isActive = true
    }

    private func makeSectionLabel(tag: String, text: String) -> UILabel? {
        let textStyle: PopupTextStyle
        switch tag.lowercased() {
        case "h3":
            textStyle = style.headingThreePopupTextStyle
        case "p", "footer":
            textStyle = style.paragraphPopupTextStyle
        case "connector":
            textStyle = style.connectorPopupTextStyle
        default:
            return nil
        }
        return Self.makeLabel(withText: text.toAttributedString(), style: textStyle)
    }

    private static func makeContainerView(
        backgroundColor: UIColor,
        borderColor: CGColor
    ) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = backgroundColor
        container.layer.cornerRadius = 8
        container.layer.masksToBounds = true
        container.layer.borderColor = borderColor
        container.layer.borderWidth = 1
        return container
    }

    private static func makeLabel(
        withText text: NSAttributedString,
        style: PopupTextStyle,
        alignment: NSTextAlignment = .center
    ) -> UILabel {
        let label = UILabel()
        label.textAlignment = alignment
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0

        guard let font = style.font, text.length > 0 else {
            label.attributedText = text
            label.applyTextStyle(style: style)
            return label
        }

        let mutable = NSMutableAttributedString(attributedString: text)
        let range = NSRange(location: 0, length: mutable.length)
        applyFont(font, to: mutable, in: range)
        mutable.addAttribute(.foregroundColor, value: style.textColor, range: range)
        mutable.enumerateAttribute(.paragraphStyle, in: range, options: []) { value, range, _ in
            let paragraph =
                ((value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle)
                ?? NSMutableParagraphStyle()
            paragraph.alignment = alignment
            mutable.addAttribute(.paragraphStyle, value: paragraph, range: range)
        }
        label.attributedText = mutable
        return label
    }

    private static func makeDisclosureTextView(
        text: NSAttributedString,
        rawHTML: String,
        style: PopupTextStyle
    ) -> UITextView {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0

        let mutable = NSMutableAttributedString(attributedString: text)
        let range = NSRange(location: 0, length: mutable.length)
        if !mutable.string.isEmpty {
            mutable.addAttribute(.foregroundColor, value: style.textColor, range: range)
        }
        if let font = style.font, !mutable.string.isEmpty {
            applyFont(font, to: mutable, in: range)
        }

        if let document = try? SwiftSoup.parse(rawHTML) {
            let anchors = (try? document.select("a[href]").array()) ?? []
            let source = mutable.string as NSString
            for anchor in anchors {
                guard
                    let href = try? anchor.attr("href"),
                    let url = URL(string: href),
                    let linkText = try? anchor.text(),
                    !href.isEmpty,
                    !linkText.isEmpty
                else { continue }

                let found = source.range(of: linkText)
                guard found.location != NSNotFound else { continue }
                mutable.addAttribute(.link, value: url, range: found)
            }
        }

        textView.attributedText = mutable
        textView.linkTextAttributes = [
            .foregroundColor: style.textColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ]
        return textView
    }

    private static func applyFont(
        _ targetFont: UIFont,
        to mutable: NSMutableAttributedString,
        in range: NSRange
    ) {
        mutable.enumerateAttribute(.font, in: range, options: []) { value, range, _ in
            let newFont: UIFont
            if let existingFont = value as? UIFont {
                let traits = targetFont.fontDescriptor.symbolicTraits
                    .union(existingFont.fontDescriptor.symbolicTraits)
                if let descriptor = targetFont.fontDescriptor
                    .withFamily(targetFont.familyName)
                    .withSymbolicTraits(traits)
                {
                    newFont = UIFont(
                        descriptor: descriptor.withSize(targetFont.pointSize),
                        size: targetFont.pointSize
                    )
                } else {
                    newFont = targetFont
                }
            } else {
                newFont = targetFont
            }
            mutable.addAttribute(.font, value: newFont, range: range)
        }
    }

    private static func makeActionButton(
        title: String,
        style: PopupActionButtonStyle?
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = style?.font
        button.setTitleColor(style?.textColor ?? .white, for: .normal)
        button.backgroundColor = style?.backgroundColor ?? UIColor(hex: "d50132")
        button.layer.cornerRadius = style?.cornerRadius ?? 8
        button.layer.masksToBounds = true
        return button
    }
}
