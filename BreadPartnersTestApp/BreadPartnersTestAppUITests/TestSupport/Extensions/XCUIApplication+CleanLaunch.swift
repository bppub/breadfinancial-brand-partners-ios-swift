//------------------------------------------------------------------------------
//  File:          XCUIApplication+Launch.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Foundation
import XCTest

extension XCUIApplication {
    /// Launches with all persisted test-app data wiped so tests don't share state.
    func launchFresh() {
        if !launchArguments.contains(MockServerKeys.resetState) {
            launchArguments.append(MockServerKeys.resetState)
        }
        launch()
    }
}
