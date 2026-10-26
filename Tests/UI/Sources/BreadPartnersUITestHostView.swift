//------------------------------------------------------------------------------
//  File:          BreadPartnersUITestHostView.swift
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

struct BreadPartnersUITestHostChild {
    let identifier: String
    let makeView: () -> AnyView
}

struct BreadPartnersUITestHostView: View {
    private let content: AnyView

    init(children: [BreadPartnersUITestHostChild]) {
        let selectedIdentifier = ProcessInfo.processInfo.environment["BREAD_PARTNERS_UI_TEST_CHILD"]
        let selectedChild = children.first { $0.identifier == selectedIdentifier }
        content = selectedChild?.makeView() ?? AnyView(Text("No UI test child selected"))
    }

    var body: some View {
        content
    }
}
