//------------------------------------------------------------------------------
//  File:          LiveHTTPClientTests.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import BreadPartnersTestSupport
import Foundation
import Testing
@testable import BreadPartners

@Suite(.serialized) struct LiveHTTPClientTests {
    private let url = URL(string: "https://example.com/api")!

    private func client(
        session: HTTPDataLoadingSpy,
        logger: Logger = Logger()
    ) -> LiveHTTPClient {
        return LiveHTTPClient(
            logger: logger,
            session: session
        )
    }

    private func request(
        headers: [String: String] = [:],
        cookies: String? = nil,
        body: Data? = nil
    ) -> HTTPRequest {
        HTTPRequest(
            url: url,
            method: .PUT,
            headers: headers,
            cookies: cookies,
            body: body
        )
    }

    @Test
    func requestSendsHTTPFieldsAndPreservesCallerHeaders() async throws {
        let responseData = Data(#"{"ok":true}"#.utf8)
        let session = HTTPDataLoadingSpy(
            responseData: responseData,
            response: HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
        )

        let body = Data(#"{"value":42}"#.utf8)
        let result = try await client(session: session).request(
            request(
                headers: [
                    "X-Test": "value",
                    "Content-Type": "text/plain",
                ],
                cookies: "session=abc",
                body: body
            )
        )

        #expect(result == responseData)
        let capturedRequest = try #require(session.request)
        let expectedUserAgent = await DeviceInformationProvider.userAgent
        #expect(capturedRequest.url == url)
        #expect(capturedRequest.httpMethod == "PUT")
        #expect(capturedRequest.value(forHTTPHeaderField: "X-Test") == "value")
        #expect(capturedRequest.value(forHTTPHeaderField: "Content-Type") == "text/plain")
        #expect(capturedRequest.value(forHTTPHeaderField: "Cookie") == "session=abc")
        #expect(capturedRequest.httpBody == body)
        #expect(
            capturedRequest.value(forHTTPHeaderField: Constants.headerOriginKey)
                == Constants.headerOriginValue)
        #expect(
            capturedRequest.value(forHTTPHeaderField: Constants.headerPlatformKey)
                == Constants.headerPlatformValue)
        #expect(
            capturedRequest.value(forHTTPHeaderField: Constants.headerUserAgentKey)
                == expectedUserAgent)
    }

    @Test
    func requestLogsRequestAndResponseWhenLoggingIsEnabled() async throws {
        let responseData = Data(#"{"ok":true}"#.utf8)
        let session = HTTPDataLoadingSpy(
            responseData: responseData,
            response: HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
        )
        let eventBox = EventCapture()
        let logger = Logger()
        logger.setLogging(enabled: true)
        logger.setCallback { eventBox.events.append($0) }

        _ = try await client(session: session, logger: logger).request(request())

        #expect(eventBox.events.count == 2)
        #expect(eventBox.messages.contains { $0.contains("Request Details") })
        #expect(eventBox.messages.contains { $0.contains("Response Details") })
    }

}
