//------------------------------------------------------------------------------
//  File:          MockHttpResponse.swift
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

/// One canned response for `MockHTTPServer`: "when a request path contains `match`, reply with
/// this JSON body and status code".
///
/// ```swift
/// // Any path containing "/config" returns this body with status 200.
/// MockHttpResponse(match: "/config", jsonString: #"{ "brandId": "test-brand" }"#)
///
/// // Make the SDK handle a server error.
/// MockHttpResponse(match: "/generatePlacements", jsonString: "{}", statusCode: 500)
/// ```
///
/// Ready-made stubs for the endpoints the app calls live in `Fixtures`.
struct MockHttpResponse {
    /// Text to look for in the request path, e.g. `"/generatePlacements"`. It is a substring
    /// match, not an exact match, so `"/config"` also matches `"/brands/abc/config"`.
    let match: String
    /// The response body, sent exactly as given.
    let json: Data
    /// The HTTP status code. Use a non-2xx value (such as 500) to test how the SDK handles errors.
    let statusCode: Int
    /// Response headers returned to the SDK. Defaults to `application/json`, which
    /// the SDK requires; override to exercise other content types or custom headers.
    /// `Content-Length` is ignored because the server always sets it from `json`.
    let headers: [String: String]

    /// Creates a stub from raw bytes.
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

    /// Creates a stub from a JSON string, which is encoded as UTF-8. The easiest form for small
    /// inline payloads; use a raw string (`#"..."#`) to avoid escaping quotes.
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
