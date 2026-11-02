//------------------------------------------------------------------------------
//  File:          BreadPartnersUITestHost.swift
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

@main
struct UITestHostApp: App {
    var body: some Scene {
        WindowGroup {
            UITestHostView()
        }
    }
}

protocol UITestHostProviding: AnyObject {
    @MainActor static func makeView() -> AnyView
}

struct UITestHostView: View {
    private let content: AnyView

    @MainActor
    init() {
        let hostName = ProcessInfo.processInfo.environment["BREAD_PARTNERS_UI_TEST_HOST"]

        guard let hostName else {
            fatalError("Missing BREAD_PARTNERS_UI_TEST_HOST launch configuration.")
        }

        guard let hostType = NSClassFromString(hostName) as? UITestHostProviding.Type else {
            fatalError("Unable to resolve UI test host '\(hostName)'.")
        }

        content = hostType.makeView()
    }

    var body: some View {
        content
    }
}
