//------------------------------------------------------------------------------
//  File:          HTTPDataLoadingSpyTests.swift
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
import BreadPartnersTestSupport
import Foundation
import Testing

@Suite struct HTTPDataLoadingSpyTests {
    private let url = URL(string: "https://example.com/api")!

    @Test
    func returnsConfiguredResponseAndCapturesRequest() async throws {
        let responseData = Data(#"{"ok":true}"#.utf8)
        let response = HTTPURLResponse(
            url: url,
            statusCode: 201,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        let spy = HTTPDataLoadingSpy(responseData: responseData, response: response)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data(#"{"id":1}"#.utf8)

        let result = try await spy.data(for: request)

        #expect(result.0 == responseData)
        let capturedResponse = try #require(result.1 as? HTTPURLResponse)
        #expect(capturedResponse.statusCode == 201)
        #expect(capturedResponse.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(spy.request == request)
    }

    @Test
    func updatesResponseDataAndCapturedRequestOnSubsequentCalls() async throws {
        let firstURL = URL(string: "https://example.com/first")!
        let secondURL = URL(string: "https://example.com/second")!
        let response = URLResponse(
            url: firstURL,
            mimeType: "application/json",
            expectedContentLength: 0,
            textEncodingName: nil
        )
        let spy = HTTPDataLoadingSpy(responseData: Data("first".utf8), response: response)

        let firstResult = try await spy.data(for: URLRequest(url: firstURL))
        spy.responseData = Data("second".utf8)
        let secondRequest = URLRequest(url: secondURL)
        let secondResult = try await spy.data(for: secondRequest)

        #expect(firstResult.0 == Data("first".utf8))
        #expect(secondResult.0 == Data("second".utf8))
        #expect(spy.request == secondRequest)
    }

    @Test
    func recordsRequestAndThrowsConfiguredFailureWithoutWrappingIt() async throws {
        let expectedError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
        let spy = HTTPDataLoadingSpy(
            responseData: Data(),
            response: URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil),
            failure: expectedError
        )
        let request = URLRequest(url: url)

        do {
            _ = try await spy.data(for: request)
            Issue.record("Expected configured transport failure")
        } catch {
            #expect(error as NSError === expectedError)
        }
        #expect(spy.request == request)
    }
}
