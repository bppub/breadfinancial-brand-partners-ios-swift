//
//  StubsConstants.swift
//  BreadPartnersTestApp
//
//  Created by Joncarlos Tavarez on 10/20/26.
//

import Foundation

/// The wire format both sides agree on for passing HTTP stubs via
/// `XCUIApplication.launchEnvironment`.
enum StubProtocolKeys {
    static let enableKey = "UHTTP"
    static let stubsKey = "UITEST_STUBS"
    static let fieldSeparator = "|||"
    static let entrySeparator = "\n"
    static let enabledValue = "ENABLED_STUBS"
}

enum UITestLaunchFlags {
    /// Wipes persisted test-app data at launch so UI tests don't inherit each other's state.
    static let resetState = "-UITestResetState"
}
