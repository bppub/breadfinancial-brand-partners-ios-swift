//------------------------------------------------------------------------------
//  File:          HTTPDataLoadingSpy.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import BreadPartnersCore
import Foundation

package final class HTTPDataLoadingSpy: HTTPDataLoading, @unchecked Sendable {
    package var responseData: Data
    package let response: URLResponse
    private let failure: NSError?
    package private(set) var request: URLRequest?

    package init(responseData: Data, response: URLResponse, failure: NSError? = nil) {
        self.responseData = responseData
        self.response = response
        self.failure = failure
    }

    package func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        self.request = request
        if let failure {
            throw failure
        }
        return (responseData, response)
    }
}
