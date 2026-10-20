//
//  XCUIApplicationExtensions.swift
//  BreadPartnersTestApp
//
//  Created by Joncarlos Tavarez on 10/20/26.
//

import Foundation
import XCTest

extension XCUIApplication {
    /// Configures the app to serve `stubs` for matching requests during this launch.
    /// Call before `launch()`.
    ///
    /// Each stub is encoded as `match|||statusCode|||base64json|||base64headers`.
    func enableHTTPStubs(_ stubs: [HTTPStub]) {
        launchEnvironment[StubProtocolKeys.enableKey] = StubProtocolKeys.enabledValue
        launchEnvironment[StubProtocolKeys.stubsKey] = stubs
            .map { stub in
                [
                    stub.match,
                    String(stub.statusCode),
                    stub.json.base64EncodedString(),
                    Self.encodeHeaders(stub.headers),
                ].joined(separator: StubProtocolKeys.fieldSeparator)
            }
            .joined(separator: StubProtocolKeys.entrySeparator)
    }

    /// Encodes a headers dictionary as base64 JSON so it survives the field and
    /// entry separators used in the launch-environment payload. Returns an empty
    /// string when encoding fails, which the app treats as "use default headers".
    private static func encodeHeaders(_ headers: [String: String]) -> String {
        guard
            !headers.isEmpty,
            let data = try? JSONEncoder().encode(headers)
        else { return "" }
        return data.base64EncodedString()
    }
}
