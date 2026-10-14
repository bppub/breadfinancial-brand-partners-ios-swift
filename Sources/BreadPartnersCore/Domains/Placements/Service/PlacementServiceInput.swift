//------------------------------------------------------------------------------
//  File:          PlacementServiceInput.swift
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

package struct PlacementServiceInput: Sendable {
    package let httpClient: any HTTPClient
    package let request: PlacementRequest
    package let url: URL
    package let cookies: String?

    package init(
        httpClient: any HTTPClient,
        request: PlacementRequest,
        url: URL,
        cookies: String? = nil
    ) {
        self.httpClient = httpClient
        self.request = request
        self.url = url
        self.cookies = cookies
    }
}
