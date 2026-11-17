//------------------------------------------------------------------------------
//  File:          BreadPartnerLinkTextSwiftUITests.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import SwiftUI
import Testing
import UIKit
@testable import BreadPartners

struct BreadPartnerLinkTextSwiftUITests {
    @Test
    func fontResolutionUsesNamedFontOrSystemFallback() {
        let namedFont = breadPartnerLinkTextFontToUIFont(fontName: "Helvetica", size: 19)
        #expect(namedFont.fontName == "Helvetica")
        #expect(namedFont.pointSize == 19)

        let fallbackFont = breadPartnerLinkTextFontToUIFont(fontName: "Missing-Test-Font", size: 19)
        #expect(fallbackFont.isEqual(UIFont.systemFont(ofSize: 19)))
    }

    @Test
    func namedColorsMapToUIKitColors() {
        let colorMappings: [(Color, UIColor)] = [
            (.black, .black),
            (.white, .white),
            (.red, .red),
            (.green, .green),
            (.blue, .blue),
            (.gray, .gray),
            (.yellow, .yellow),
            (.orange, .orange),
            (.pink, .systemPink),
            (.purple, .purple),
        ]

        for (color, expectedColor) in colorMappings {
            #expect(breadPartnerLinkTextColorToUIColor(color).isEqual(expectedColor))
        }
    }

    @Test
    func customColorConvertsToUIKitColor() {
        let expectedColor = UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1)

        #expect(breadPartnerLinkTextColorToUIColor(Color(uiColor: expectedColor)).isEqual(expectedColor))
    }

    @MainActor
    @Test
    func labelRepresentableCreatesAndUpdatesLabelAndForwardsTap() throws {
        var tapCount = 0
        let representable = BreadPartnerLinkTextSwiftUI.UILabelRepresentable(
            attributedText: NSAttributedString(string: "Initial link"),
            onTap: { tapCount += 1 }
        )
        let hostingController = UIHostingController(rootView: representable)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 320, height: 80)
        hostingController.view.layoutIfNeeded()

        let label = try #require(findLabel(in: hostingController.view))
        #expect(label.attributedText?.string == "Initial link")
        #expect(label.numberOfLines == 0)
        #expect(label.isUserInteractionEnabled)
        #expect(label.gestureRecognizers?.contains { $0 is UITapGestureRecognizer } == true)

        let coordinator = representable.makeCoordinator()
        coordinator.handleTap()
        #expect(tapCount == 1)

        hostingController.rootView = BreadPartnerLinkTextSwiftUI.UILabelRepresentable(
            attributedText: NSAttributedString(string: "Updated link"),
            onTap: { tapCount += 1 }
        )
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        #expect(label.attributedText?.string == "Updated link")
    }
}

@MainActor
private func findLabel(in view: UIView) -> UILabel? {
    if let label = view as? UILabel {
        return label
    }

    for subview in view.subviews {
        if let label = findLabel(in: subview) {
            return label
        }
    }

    return nil
}
