//
//  HTTPStub.swift
//  BreadPartnersTestApp
//
//  Created by Joncarlos Tavarez on 10/20/26.
//

import Foundation

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
