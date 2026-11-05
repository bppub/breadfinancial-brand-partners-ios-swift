//------------------------------------------------------------------------------
//  File:          PopupLoadingView.swift
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
internal final class PopupLoadingView: UIView {
    private static let indicatorSize: CGFloat = 50
    private let indicator: LoaderIndicator

    init(color: UIColor) {
        indicator = LoaderIndicator(
            frame: CGRect(x: 0, y: 0, width: Self.indicatorSize, height: Self.indicatorSize),
            color: color
        )
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        indicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(indicator)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Self.indicatorSize),
            heightAnchor.constraint(equalToConstant: Self.indicatorSize),
            indicator.topAnchor.constraint(equalTo: topAnchor),
            indicator.leadingAnchor.constraint(equalTo: leadingAnchor),
            indicator.trailingAnchor.constraint(equalTo: trailingAnchor),
            indicator.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        stopAnimating()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func install(in parentView: UIView) {
        parentView.addSubview(self)
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
            centerYAnchor.constraint(equalTo: parentView.centerYAnchor),
        ])
    }

    func startAnimating() {
        isHidden = false
        indicator.startAnimating()
    }

    func stopAnimating() {
        indicator.stopAnimating()
        isHidden = true
    }
}
