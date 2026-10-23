//------------------------------------------------------------------------------
//  File:          BreadPartnersTestApp.swift
//  Author(s):     Bread Financial
//
//  Description:   Entry point for the BreadPartners SDK test application.
//                 This standalone iOS app depends on the local Swift package
//                 located at the repository root and demonstrates how to
//                 integrate and exercise the SDK's public API.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import SwiftUI
import BreadPartners

@main
struct BreadPartnersTestApp: App {
    init() {
        if ProcessInfo.processInfo.arguments.contains(MockServerKeys.resetState) {
            PreferencesManager.shared.clearAll()
            HTTPCookieStorage.shared.removeCookies(since: .distantPast)
            URLCache.shared.removeAllCachedResponses()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
