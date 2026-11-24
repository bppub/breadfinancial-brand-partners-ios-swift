//------------------------------------------------------------------------------
//  File:          PlacementTextComponentsTestHost.swift
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
import UIKit
@testable import BreadPartners

@objc(PlacementTextComponentsTestHost)
final class PlacementTextComponentsTestHost: NSObject, UITestHostProviding {
    @MainActor
    static func makeView() -> AnyView {
        AnyView(PlacementTextComponentsTestHostView())
    }
}

private struct PlacementTextComponentsTestHostView: View {
    @State private var buttonResult = "Buttons ready"
    @State private var linkResult = "Links ready"
    @State private var legacyLinkText = "Legacy UILabel link"
    @State private var plainTapCount = 0

    var body: some View {
        let currentLegacyText = legacyLinkText

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BreadPartnerTextView("Default text variant")

                BreadPartnerTextView("Styled text variant")
                    .font(.headline)
                    .textColor(.red)
                    .backgroundColor(.yellow)
                    .padding(12)
                    .alignment(.center)

                BreadPartnerButtonView("Default action") {
                    buttonResult = "Default button tapped"
                }

                BreadPartnerButtonView("Styled action") {
                    buttonResult = "Styled button tapped"
                }
                .font(.body)
                .textColor(.black)
                .backgroundColor(.green)
                .cornerRadius(2)
                .padding(12)
                .alignment(.leading)

                Text(buttonResult)
                    .accessibilityIdentifier("button-result")

                BreadPartnerLinkTextSwiftUI(
                    "Plain linked text variant",
                    links: ["linked"],
                    onTap: {
                        plainTapCount += 1
                        linkResult = "Plain link tapped \(plainTapCount)"
                    }
                )

                BreadPartnerLinkTextSwiftUI(
                    attributedString: NSAttributedString(
                        string: "Attributed text variant",
                        attributes: [.font: UIFont.boldSystemFont(ofSize: 17)]
                    ),
                    onTap: { linkResult = "Attributed link tapped" }
                )

                BreadPartnerLinkTextSwiftUI.UILabelRepresentable(
                    attributedText: NSAttributedString(string: legacyLinkText),
                    onTap: {
                        linkResult =
                            currentLegacyText == "Legacy UILabel link"
                            ? "Original legacy handler" : "Updated legacy handler"
                    },
                    accessibilityId: "legacy-label"
                )
                .frame(minHeight: 44)

                Button("Update legacy label") {
                    legacyLinkText = "Updated legacy UILabel link"
                }
                .accessibilityIdentifier("update-legacy-label")

                UIKitLinkTextRepresentable {
                    linkResult = "UIKit link tapped"
                }
                .frame(height: 52)

                Text(linkResult)
                    .accessibilityIdentifier("link-result")

                BreadPartnerLinkTextSwiftUI("No action link")
                    .accessibilityIdentifier("no-action-link")
            }
            .padding()
        }
    }
}

private struct UIKitLinkTextRepresentable: UIViewRepresentable {
    let onTap: () -> Void

    func makeUIView(context: Context) -> BreadPartnerLinkText {
        let textView = BreadPartnerLinkText()
        textView.accessibilityIdentifier = "UIKit link text"
        configure(textView)
        return textView
    }

    func updateUIView(_ uiView: BreadPartnerLinkText, context: Context) {
        configure(uiView)
    }

    private func configure(_ textView: BreadPartnerLinkText) {
        textView.configure(
            with: NSAttributedString(string: "UIKit linked text variant"),
            tapHandler: { _ in onTap() }
        )
    }
}
