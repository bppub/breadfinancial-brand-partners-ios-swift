//------------------------------------------------------------------------------
//  File:          BreadPartnerTextView.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

import SwiftUI

/// A SwiftUI view for rendering styled text content in the Bread Partner UI.
public struct BreadPartnerTextView: View {
    var text: String
    private var font: Font = .body
    private var textColor: Color = .black
    private var backgroundColor: Color = .clear
    private var padding: CGFloat = 8.0
    private var alignment: TextAlignment = .leading

    public init(_ text: String) {
        self.text = text
    }

    public func font(_ font: Font) -> BreadPartnerTextView {
        var copy = self
        copy.font = font
        return copy
    }

    public func textColor(_ color: Color) -> BreadPartnerTextView {
        var copy = self
        copy.textColor = color
        return copy
    }

    public func backgroundColor(_ color: Color) -> BreadPartnerTextView {
        var copy = self
        copy.backgroundColor = color
        return copy
    }

    public func padding(_ value: CGFloat) -> BreadPartnerTextView {
        var copy = self
        copy.padding = value
        return copy
    }

    public func alignment(_ alignment: TextAlignment) -> BreadPartnerTextView {
        var copy = self
        copy.alignment = alignment
        return copy
    }

    public var body: some View {
        Text(text)
            .font(font)
            .foregroundColor(textColor)
            .background(backgroundColor)
            .padding(padding)
            .multilineTextAlignment(alignment)  // Applying alignment
    }
}
