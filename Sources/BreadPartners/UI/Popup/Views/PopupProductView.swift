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

    private let contentView = UIView()
    let headerView = UIView()
    private let dividerBottom = UIView()
    private let style: PopUpStyling
    private let onAction: () -> Void

    init(presentation: PopupProductPresentationModel, onAction: @escaping () -> Void) {
        self.style = presentation.style
        self.onAction = onAction

        titleLabel = Self.makeLabel(withText: presentation.title)
        subtitleLabel = Self.makeLabel(withText: presentation.subtitle)
        disclosureTextView = Self.makeDisclosureTextView(
            text: presentation.disclosure,
            style: style.disclosurePopupTextStyle
        )
        detailsView = Self.makeContainerView(
            backgroundColor: style.backgroundColor,
            borderColor: style.borderColor
        )
        headerLabel = Self.makeLabel(withText: presentation.header)
        sectionStackView = UIStackView()
        actionButton = Self.makeActionButton(
            title: presentation.actionTitle,
            style: style.actionButtonStyle
        )
        super.init(frame: .zero)

        disclosureTextView.delegate = self
        actionButton.addTarget(self, action: #selector(actionButtonTapped(_:)), for: .touchUpInside)
        configure(presentation: presentation)
        installConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func actionButtonTapped(_ sender: UIButton) {
        onAction()
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

    private func configure(presentation: PopupProductPresentationModel) {
        translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        bottomRowView.translatesAutoresizingMaskIntoConstraints = false
        headerView.translatesAutoresizingMaskIntoConstraints = false
        dividerBottom.translatesAutoresizingMaskIntoConstraints = false
        sectionStackView.translatesAutoresizingMaskIntoConstraints = false

        headerView.backgroundColor = style.headerBgColor
        headerView.isHidden = presentation.header.length == 0
        detailsView.isHidden = !presentation.showsDetailsCard
        sectionStackView.axis = .vertical
        sectionStackView.spacing = 10
        sectionStackView.alignment = .fill
        dividerBottom.backgroundColor = style.dividerColor

        for section in presentation.sections {
            sectionStackView.addArrangedSubview(Self.makeLabel(withText: section.text))
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
        withText text: NSAttributedString
    ) -> UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.attributedText = text
        return label
    }

    private static func makeDisclosureTextView(
        text: NSAttributedString,
        style: PopupTextStyle
    ) -> UITextView {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0

        textView.attributedText = text
        textView.linkTextAttributes = [
            .foregroundColor: style.textColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ]
        return textView
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
