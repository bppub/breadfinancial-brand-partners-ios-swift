//------------------------------------------------------------------------------
//  File:          PopupEmbeddedView.swift
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
import WebKit

@MainActor
internal final class PopupEmbeddedView: UIView {
    private(set) var webView: WKWebView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func install(_ webView: WKWebView) {
        self.webView?.removeFromSuperview()
        self.webView = webView
        webView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
