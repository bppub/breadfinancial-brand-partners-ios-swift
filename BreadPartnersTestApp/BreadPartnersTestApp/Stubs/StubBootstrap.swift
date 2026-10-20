//------------------------------------------------------------------------------
//  File:          StubBootstrap.swift
//  Author(s):     Bread Financial
//
//  Description:   Bridges the out-of-process UI test to the in-process
//                 StubURLProtocol. UI tests cannot inject objects into the
//                 running app, so they pass stub fixtures via launchEnvironment;
//                 this type reads them at launch and registers the interceptor.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Foundation

/// Configures HTTP stubbing based on values provided by a UI test through
/// `XCUIApplication.launchEnvironment`.
///
/// Expected launch environment keys:
/// - `UITEST_STUB_HTTP` = `"1"`         → enables stubbing.
/// - `UITEST_STUBS`     = newline-separated entries of the form
///   `match|||statusCode|||base64json`.
///
/// Example (in a UI test):
/// ```swift
/// app.launchEnvironment["UITEST_STUB_HTTP"] = "1"
/// app.launchEnvironment["UITEST_STUBS"] = [
///     "/config|||200|||" + configJSON.base64EncodedString(),
///     "/generatePlacements|||200|||" + placementsJSON.base64EncodedString()
/// ].joined(separator: "\n")
/// ```
///
/// Response headers may optionally be supplied as a fourth field containing a
/// base64-encoded JSON `[String: String]` dictionary, i.e.
/// `match|||statusCode|||base64json|||base64headers`. When omitted, the stub
/// defaults to `Content-Type: application/json`.
enum StubBootstrap {
    /// Returns `true` when the app was launched by a UI test requesting HTTP stubs.
    static var isStubbingEnabled: Bool {
        ProcessInfo.processInfo.environment[StubProtocolKeys.enableKey] == StubProtocolKeys.enabledValue
    }

    /// Registers `StubURLProtocol` and loads any stubs described in the launch
    /// environment. Safe to call unconditionally; it is a no-op when stubbing is off.
    static func configureFromLaunchEnvironment() {
        guard isStubbingEnabled else { return }

        StubURLProtocol.reset()
        URLProtocol.registerClass(StubURLProtocol.self)

        let raw = ProcessInfo.processInfo.environment[StubProtocolKeys.stubsKey] ?? ""
        for line in raw.split(separator: StubProtocolKeys.entrySeparator, omittingEmptySubsequences: true) {
            let parts = String(line).components(separatedBy: StubProtocolKeys.fieldSeparator)
            switch parts.count {
            case 4:
                // match|||statusCode|||base64json|||base64headers
                guard let status = Int(parts[1]), let json = Data(base64Encoded: parts[2]) else { continue }
                if let headers = decodeHeaders(parts[3]) {
                    StubURLProtocol.register(match: parts[0], json: json, statusCode: status, headers: headers)
                } else {
                    StubURLProtocol.register(match: parts[0], json: json, statusCode: status)
                }
            case 3:
                // match|||statusCode|||base64json
                guard let status = Int(parts[1]), let json = Data(base64Encoded: parts[2]) else { continue }
                StubURLProtocol.register(match: parts[0], json: json, statusCode: status)
            case 2:
                // Backward-compatible: match|||base64json (defaults to 200).
                guard let json = Data(base64Encoded: parts[1]) else { continue }
                StubURLProtocol.register(match: parts[0], json: json)
            default:
                continue
            }
        }
    }

    /// Decodes a base64-encoded JSON `[String: String]` headers dictionary.
    /// Returns `nil` when the payload is empty or cannot be decoded, letting the
    /// caller fall back to the default headers.
    private static func decodeHeaders(_ encoded: String) -> [String: String]? {
        guard
            !encoded.isEmpty,
            let data = Data(base64Encoded: encoded),
            let headers = try? JSONDecoder().decode([String: String].self, from: data),
            !headers.isEmpty
        else { return nil }
        return headers
    }
}
