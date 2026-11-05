//------------------------------------------------------------------------------
//  File:          PopupChromeView.swift
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
internal final class PopupChromeView: UIView {
    let closeButton: UIButton
    var contentTopAnchor: NSLayoutYAxisAnchor { topRowView.bottomAnchor }

    private let topRowView = UIView()
    private let brandLogo = UIImageView()
    private let divider = UIView()
    private let onClose: () -> Void

    init(
        style: PopUpStyling,
        configuration: PopupInput.ChromeConfiguration,
        onClose: @escaping () -> Void
    ) {
        self.onClose = onClose
        closeButton = UIButton(type: .system)
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .white
        layer.cornerRadius = 12
        layer.masksToBounds = true

        topRowView.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = style.crossColor
        closeButton.imageView?.contentMode = .scaleAspectFit
        closeButton.isHidden = !configuration.showsCloseButton
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)

        brandLogo.translatesAutoresizingMaskIntoConstraints = false
        brandLogo.contentMode = .scaleAspectFit
        brandLogo.clipsToBounds = true
        brandLogo.setContentHuggingPriority(.defaultHigh, for: .vertical)
        brandLogo.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = style.dividerColor

        addSubview(topRowView)
        topRowView.addSubview(closeButton)
        topRowView.addSubview(brandLogo)
        topRowView.addSubview(divider)

        loadLogo(from: configuration.logoURL)

        NSLayoutConstraint.activate([
            topRowView.topAnchor.constraint(equalTo: topAnchor),
            topRowView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topRowView.trailingAnchor.constraint(equalTo: trailingAnchor),

            closeButton.trailingAnchor.constraint(equalTo: topRowView.trailingAnchor, constant: -10),
            closeButton.topAnchor.constraint(equalTo: topRowView.topAnchor, constant: 25),

            brandLogo.leadingAnchor.constraint(equalTo: topRowView.leadingAnchor, constant: 10),
            brandLogo.topAnchor.constraint(equalTo: topRowView.topAnchor, constant: 10),
            brandLogo.heightAnchor.constraint(equalToConstant: 50),
            brandLogo.widthAnchor.constraint(lessThanOrEqualToConstant: 150),

            divider.topAnchor.constraint(equalTo: brandLogo.bottomAnchor, constant: 10),
            divider.leadingAnchor.constraint(equalTo: topRowView.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: topRowView.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),
            divider.bottomAnchor.constraint(equalTo: topRowView.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func install(in parentView: UIView) {
        parentView.addSubview(self)
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.centerXAnchor),
            centerYAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.centerYAnchor),
            widthAnchor.constraint(equalTo: parentView.widthAnchor, multiplier: 0.9),
            heightAnchor.constraint(
                equalTo: parentView.heightAnchor,
                constant: -UIScreen.main.bounds.height * 0.1
            ),
        ])
    }

    func loadLogo(from logoURL: String) {
        guard let url = URL(string: logoURL) else { return }
        brandLogo.loadImage(from: url) { _ in }
    }

    @objc private func closeButtonTapped() {
        onClose()
    }
}
