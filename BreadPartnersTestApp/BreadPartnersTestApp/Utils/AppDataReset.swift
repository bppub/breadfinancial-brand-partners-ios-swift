//------------------------------------------------------------------------------
//  File:          AppDataReset.swift
//  Author(s):     Bread Financial
//
//  Description:   Clears the test app's persisted data.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Foundation

enum AppDataReset {
    /// Posted after the data is cleared so live screens can drop the values they hold in memory.
    static let didClear = Notification.Name("AppDataReset.didClear")

    static func clear() {
        PreferencesManager.shared.clearAll()
        HTTPCookieStorage.shared.removeCookies(since: .distantPast)
        URLCache.shared.removeAllCachedResponses()
        NotificationCenter.default.post(name: didClear, object: nil)
    }
}
