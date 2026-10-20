//------------------------------------------------------------------------------
//  File:          StubbedHTTPSupport.swift
//  Author(s):     Bread Financial
//
//  Description:   Helpers for UI tests to drive the app's StubURLProtocol via
//                 launch environment. Mirrors the keys defined in the app's
//                 StubBootstrap type.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

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


/// A single stub mapping: any request URL containing `match` returns `json`
/// with `statusCode`. Use a non-2xx `statusCode` to exercise the SDK's error path.
struct HTTPStub {
    let match: String
    let json: Data
    let statusCode: Int
    /// Response headers returned to the SDK. Defaults to `application/json`, which
    /// the SDK requires; override to exercise other content types or custom headers.
    let headers: [String: String]

    init(
        match: String,
        json: Data,
        statusCode: Int = 200,
        headers: [String: String] = ["Content-Type": "application/json"]
    ) {
        self.match = match
        self.json = json
        self.statusCode = statusCode
        self.headers = headers
    }

    init(
        match: String,
        jsonString: String,
        statusCode: Int = 200,
        headers: [String: String] = ["Content-Type": "application/json"]
    ) {
        self.init(
            match: match,
            json: Data(jsonString.utf8),
            statusCode: statusCode,
            headers: headers
        )
    }
}

/// Canned JSON payloads for the endpoints exercised by UI tests.
///
/// Replace the placeholder bodies with captured real responses to render actual
/// placement content. The brand-config stub is required for *every* test because
/// `BreadPartnersSDK.setup` fetches it before any other call.
enum Fixtures {

    /// Minimal brand config returned from `/brands/{id}/config`.
    static let brandConfig = HTTPStub(
        match: "/config",
        jsonString: #"{ "brandId": "test-brand", "config": {} }"#
    )

    /// Minimal brand style returned from `/brands/{id}/style`.
    static let brandStyle = HTTPStub(
        match: "/style",
        jsonString: #"{ "style": {} }"#
    )

    /// Placeholder placements response returned from `/generatePlacements`.
    /// Replace with a captured response to assert on rendered content.
    static let generatePlacements = HTTPStub(
        match: "/generatePlacements",
        jsonString: #"{ "placements": [] }"#
    )
}
