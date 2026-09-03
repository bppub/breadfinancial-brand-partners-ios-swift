//------------------------------------------------------------------------------
//  File:          BreadPartnerButtonView.swift
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

/// A SwiftUI view representing the Bread Partner action button.
public struct BreadPartnerButtonView: View {
    var title: String
    private var font: Font = .headline
    private var textColor: Color = .white
    private var backgroundColor: Color = .blue
    private var cornerRadius: CGFloat = 8.0
    private var padding: CGFloat = 8.0
    private var alignment: Alignment = .center
    private var action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public func font(_ font: Font) -> BreadPartnerButtonView {
        var copy = self
        copy.font = font
        return copy
    }

    public func textColor(_ color: Color) -> BreadPartnerButtonView {
        var copy = self
        copy.textColor = color
        return copy
    }

    public func backgroundColor(_ color: Color) -> BreadPartnerButtonView {
        var copy = self
        copy.backgroundColor = color
        return copy
    }

    public func cornerRadius(_ radius: CGFloat) -> BreadPartnerButtonView {
        var copy = self
        copy.cornerRadius = radius
        return copy
    }

    public func padding(_ value: CGFloat) -> BreadPartnerButtonView {
        var copy = self
        copy.padding = value
        return copy
    }

    public func alignment(_ alignment: Alignment) -> BreadPartnerButtonView {
        var copy = self
        copy.alignment = alignment
        return copy
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(font)
                .foregroundColor(textColor)
                .padding()
                .background(backgroundColor)
                .cornerRadius(cornerRadius)
        }
        .frame(maxWidth: .infinity, alignment: alignment)  // Corrected alignment logic
        .padding(padding)
    }
}
