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

/// A single stub mapping: any request URL containing `match` returns `json`
/// with `statusCode`. Use a non-2xx `statusCode` to exercise the SDK's error path.
struct MockHttpResponse {
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

extension MockHttpResponse {
    /// Loads the body from `<name>.json` in the UI test bundle.
    init(match: String, fixture name: String, statusCode: Int = 200) {
        self.init(match: match, json: FixtureLoader.data(named: name), statusCode: statusCode)
    }
}

private enum FixtureLoader {
    private final class BundleToken {}

    static func data(named name: String) -> Data {
        guard
            let url = Bundle(for: BundleToken.self).url(forResource: name, withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else {
            preconditionFailure("Missing fixture \(name).json in the UI test bundle")
        }
        return data
    }
}
