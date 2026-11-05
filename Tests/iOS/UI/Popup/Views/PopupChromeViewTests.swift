//------------------------------------------------------------------------------
//  File:          PopupChromeViewTests.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Foundation
import Testing
import UIKit
@testable import BreadPartners

@Suite
@MainActor
struct PopupChromeViewTests {
    @Test
    func installsPopupFrameAndConfiguresCloseButton() {
        let parentView = UIView()
        parentView.frame = CGRect(x: 0, y: 0, width: 400, height: 800)
        let chromeView = PopupChromeView(
            style: PopUpStyling(crossColor: .systemRed),
            configuration: PopupInput.ChromeConfiguration(logoURL: "", showsCloseButton: false),
            onClose: {}
        )

        chromeView.install(in: parentView)
        parentView.layoutIfNeeded()

        #expect(chromeView.superview === parentView)
        #expect(chromeView.backgroundColor == .white)
        #expect(chromeView.layer.cornerRadius == 12)
        #expect(chromeView.closeButton.isHidden)
        #expect(chromeView.closeButton.tintColor == .systemRed)
        #expect(chromeView.frame.width == 360)
        #expect(chromeView.frame.midX == parentView.bounds.midX)
        #expect(chromeView.frame.midY == parentView.bounds.midY)
        #expect(chromeView.frame.height > 0)
    }

    @Test
    func closeButtonForwardsAction() {
        var closeCount = 0
        let chromeView = PopupChromeView(
            style: PopUpStyling(),
            configuration: PopupInput.ChromeConfiguration(logoURL: "", showsCloseButton: true),
            onClose: { closeCount += 1 }
        )

        chromeView.perform(NSSelectorFromString("closeButtonTapped"))

        #expect(closeCount == 1)
    }

    @Test
    func contentTopAnchorPositionsContentBelowChromeRow() {
        let parentView = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        let chromeView = PopupChromeView(
            style: PopUpStyling(),
            configuration: PopupInput.ChromeConfiguration(logoURL: "", showsCloseButton: false),
            onClose: {}
        )
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        chromeView.addSubview(contentView)
        chromeView.install(in: parentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: chromeView.contentTopAnchor),
            contentView.leadingAnchor.constraint(equalTo: chromeView.leadingAnchor),
            contentView.widthAnchor.constraint(equalToConstant: 1),
            contentView.heightAnchor.constraint(equalToConstant: 1),
        ])
        parentView.layoutIfNeeded()

        #expect(abs(contentView.frame.minY - 71) < 0.001)
    }

    @Test
    func loadLogoIgnoresInvalidURL() throws {
        let chromeView = PopupChromeView(
            style: PopUpStyling(),
            configuration: PopupInput.ChromeConfiguration(logoURL: "", showsCloseButton: false),
            onClose: {}
        )
        let invalidURL = "http://[::1"

        #expect(URL(string: invalidURL) == nil)
        chromeView.loadLogo(from: invalidURL)

        let logoImageView = try #require(logoImageView(in: chromeView))
        #expect(logoImageView.image == nil)
    }

    @Test
    func loadLogoLoadsImageFromLocalURL() async throws {
        let rendererFormat = UIGraphicsImageRendererFormat()
        rendererFormat.scale = 1
        let sourceImage = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1), format: rendererFormat)
            .image { context in
                UIColor.systemBlue.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
            }
        let imageData = try #require(sourceImage.pngData())
        let imageURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        try imageData.write(to: imageURL)
        defer { try? FileManager.default.removeItem(at: imageURL) }

        let chromeView = PopupChromeView(
            style: PopUpStyling(),
            configuration: PopupInput.ChromeConfiguration(
                logoURL: imageURL.absoluteString,
                showsCloseButton: false
            ),
            onClose: {}
        )
        let logoImageView = try #require(logoImageView(in: chromeView))

        for _ in 0..<100 where logoImageView.image == nil {
            try await Task.sleep(nanoseconds: 10_000_000)
        }

        #expect(logoImageView.image?.size == sourceImage.size)
    }

    private func logoImageView(in chromeView: PopupChromeView) -> UIImageView? {
        imageViews(in: chromeView).first { $0 !== chromeView.closeButton.imageView }
    }

    private func imageViews(in view: UIView) -> [UIImageView] {
        view.subviews.flatMap { subview in
            if let imageView = subview as? UIImageView {
                return [imageView]
            }
            return imageViews(in: subview)
        }
    }
}
