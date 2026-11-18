//------------------------------------------------------------------------------
//  File:          BreadPartnerLinkTextSwiftUI.swift
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

/// A SwiftUI view for displaying tappable link-styled text in Bread Partner UI.
public struct BreadPartnerLinkTextSwiftUI: View {
    var text: String
    private var links: [String]
    var onTap: (() -> Void)?
    private var linkColor: Color
    private var linkFontName: String
    private var linkFontSize: CGFloat
    var attributedText: NSAttributedString?
    private var accessibilityId: String?

    public init(
        _ text: String, links: [String] = [], onTap: (() -> Void)? = nil,
        fontName: String = "System", fontSize: CGFloat = 17
    ) {
        self.text = text
        self.links = links
        self.onTap = onTap
        self.linkColor = .blue
        self.linkFontName = fontName
        self.linkFontSize = fontSize
        self.attributedText = nil
        self.accessibilityId = nil
    }

    /// Initializer for attributed string (with HTML formatting preserved)
    public init(
        attributedString: NSAttributedString, onTap: (() -> Void)? = nil
    ) {
        self.text = attributedString.string
        self.links = []
        self.onTap = onTap
        self.linkColor = .blue
        self.linkFontName = "System"
        self.linkFontSize = 17
        self.attributedText = attributedString
        self.accessibilityId = nil
    }

    var resolvedAttributedText: NSAttributedString {
        // Use provided attributedText if available (for HTML formatted content)
        let finalAttributedString: NSAttributedString

        if let providedAttributedText = attributedText {
            finalAttributedString = providedAttributedText
        } else {
            // Build attributed string from plain text and links
            let attributedString = NSMutableAttributedString(string: text)
            let fullRange = NSRange(location: 0, length: attributedString.length)
            attributedString.addAttribute(
                .font, value: breadPartnerLinkTextFontToUIFont(fontName: linkFontName, size: linkFontSize),
                range: fullRange)

            let nsText = NSString(string: text)

            for word in links {
                let wordRange = nsText.range(of: word)
                if wordRange.location != NSNotFound {
                    attributedString.addAttribute(
                        .foregroundColor, value: breadPartnerLinkTextColorToUIColor(linkColor), range: wordRange)
                    attributedString.addAttribute(
                        .underlineStyle, value: NSUnderlineStyle.single.rawValue, range: wordRange)
                    attributedString.addAttribute(
                        .font, value: breadPartnerLinkTextFontToUIFont(fontName: linkFontName, size: linkFontSize),
                        range: wordRange)
                }
            }

            finalAttributedString = attributedString
        }

        return finalAttributedString
    }

    var resolvedAccessibilityIdentifier: String {
        accessibilityId ?? text
    }

    public var body: some View {
        if #available(iOS 15.0, *) {
            return AnyView(
                Text(AttributedString(resolvedAttributedText))
                    .onTapGesture { onTap?() }
                    .padding()
                    .accessibilityIdentifier(resolvedAccessibilityIdentifier)
            )
        } else {
            return AnyView(
                UILabelRepresentable(
                    attributedText: resolvedAttributedText,
                    onTap: onTap,
                    accessibilityId: resolvedAccessibilityIdentifier
                )
                .padding()
            )
        }
    }

    struct UILabelRepresentable: UIViewRepresentable {
        var attributedText: NSAttributedString
        var onTap: (() -> Void)?
        var accessibilityId: String = ""

        func makeUIView(context: Context) -> UILabel {
            let label = UILabel()
            label.numberOfLines = 0
            label.isUserInteractionEnabled = true
            label.accessibilityIdentifier = accessibilityId
            let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
            label.addGestureRecognizer(tap)
            return label
        }

        func updateUIView(_ uiView: UILabel, context: Context) {
            uiView.attributedText = attributedText
            uiView.accessibilityIdentifier = accessibilityId
            context.coordinator.onTap = onTap
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(onTap: onTap)
        }

        class Coordinator: NSObject {
            var onTap: (() -> Void)?
            init(onTap: (() -> Void)?) {
                self.onTap = onTap
            }
            @objc func handleTap() {
                onTap?()
            }
        }
    }

    public func linkColor(_ color: Color) -> BreadPartnerLinkTextSwiftUI {
        var copy = self
        copy.linkColor = color
        return copy
    }

    public func linkFont(_ fontName: String, fontSize: CGFloat)
        -> BreadPartnerLinkTextSwiftUI
    {
        var copy = self
        copy.linkFontName = fontName
        copy.linkFontSize = fontSize
        return copy
    }

    public func accessibilityIdentifier(_ id: String) -> BreadPartnerLinkTextSwiftUI {
        var copy = self
        copy.accessibilityId = id
        return copy
    }
}

// Helper function to convert Font Name and Size to UIFont
func breadPartnerLinkTextFontToUIFont(fontName: String, size: CGFloat) -> UIFont {
    if let customFont = UIFont(name: fontName, size: size) {
        return customFont
    } else {
        // Fallback to system font if the custom font is not found
        return UIFont.systemFont(ofSize: size)
    }
}

// Helper function to convert SwiftUI Color to UIColor for iOS 12+
func breadPartnerLinkTextColorToUIColor(_ color: Color) -> UIColor {
    // Handle common colors
    switch color {
    case .black: return UIColor.black
    case .white: return UIColor.white
    case .red: return UIColor.red
    case .green: return UIColor.green
    case .blue: return UIColor.blue
    case .gray: return UIColor.gray
    case .yellow: return UIColor.yellow
    case .orange: return UIColor.orange
    case .pink: return UIColor.systemPink
    case .purple: return UIColor.purple
    default:
        // Try to extract RGBA components (works for custom colors in iOS 14+)
        #if canImport(UIKit)
            if #available(iOS 14.0, *) {
                let uiColor = UIColor(color)
                return uiColor
            }
        #endif
        // Fallback to black for unknown colors on iOS 12/13
        return UIColor.black
    }
}
