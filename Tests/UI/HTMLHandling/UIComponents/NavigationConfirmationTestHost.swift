//------------------------------------------------------------------------------
//  File:          NavigationConfirmationTestHost.swift
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
@testable import BreadPartners

enum NavigationConfirmationTestHost {
    static let registration = BreadPartnersUITestHostChild(
        identifier: "navigation-confirmation",
        makeView: { AnyView(NavigationConfirmationTestHostView()) }
    )
}

private struct NavigationConfirmationTestHostView: View {
    @State private var result = "Ready"

    var body: some View {
        VStack(spacing: 16) {
            Button("Show confirmation") {
                let didPresent = UIKitNavigationConfirmationPresenter().presentNavigationConfirmation(
                    onLeave: { result = "Leave selected" },
                    onStay: { result = "Stay selected" }
                )
                if !didPresent {
                    result = "No presenter"
                }
            }
            .accessibilityIdentifier("show-confirmation")

            Text(result)
                .accessibilityIdentifier("confirmation-result")
        }
        .padding()
    }
}
