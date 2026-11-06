//------------------------------------------------------------------------------
//  File:          HTTPClientFactory.swift
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

protocol HTTPClientFactory: Sendable {
    func makeClient(logger: Logger) -> any HTTPClient
}

final class LiveHTTPClientFactory: HTTPClientFactory, @unchecked Sendable {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func makeClient(logger: Logger) -> any HTTPClient {
        LiveHTTPClient(logger: logger, session: session)
    }
}
