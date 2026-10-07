//------------------------------------------------------------------------------
//  File:          FoundationHTTPClientTests.swift
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

@Suite struct FoundationHTTPClientTests {
    private let url = URL(string: "https://example.com/api")!

    private func session(
        data: Data = Data(#"{"ok":true}"#.utf8),
        statusCode: Int = 200,
        headers: [String: String] = ["Content-Type": "application/json"]
    ) -> HTTPDataLoadingSpy {
        HTTPDataLoadingSpy(
            responseData: data,
            response: HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: headers)!
        )
    }

    @Test
    func sendsHTTPFieldsWithCallerHeadersAndExplicitCookiePrecedence() async throws {
        let session = session()
        let client = FoundationHTTPClient(
            session: session,
            defaultHeaders: {
                ["Content-Type": "application/json", "User-Agent": "device", "Origin": "default", "platform": "ios"]
            }
        )
        let body = Data(#"{"value":42}"#.utf8)
        let data = try await client.request(
            HTTPRequest(
                url: url, method: .PUT,
                headers: ["Content-Type": "text/plain", "User-Agent": "caller", "Origin": "caller", "Cookie": "old"],
                cookies: "session=abc", body: body
            )
        )

        #expect(data == session.responseData)
        let request = try #require(session.request)
        #expect(request.url == url)
        #expect(request.httpMethod == "PUT")
        #expect(request.httpBody == body)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "text/plain")
        #expect(request.value(forHTTPHeaderField: "User-Agent") == "caller")
        #expect(request.value(forHTTPHeaderField: "Origin") == "caller")
        #expect(request.value(forHTTPHeaderField: "platform") == "ios")
        #expect(request.value(forHTTPHeaderField: "Cookie") == "session=abc")
    }

    @Test
    func nilCookiesPreserveCallerCookieAndNilBody() async throws {
        let session = session()
        _ = try await FoundationHTTPClient(session: session).request(
            HTTPRequest(url: url, method: .GET, headers: ["Cookie": "caller-cookie"])
        )

        #expect(session.request?.httpBody == nil)
        #expect(session.request?.value(forHTTPHeaderField: "Cookie") == "caller-cookie")
        #expect(session.request?.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test(arguments: [200, 204, 299])
    func acceptsSuccessfulStatusAndReturnsUnparsedJSONData(statusCode: Int) async throws {
        let session = session(
            data: Data("not decoded here".utf8), statusCode: statusCode,
            headers: [
                "Content-Type": "application/json; charset=utf-8"
            ])
        let data = try await FoundationHTTPClient(session: session).request(HTTPRequest(url: url, method: .POST))
        #expect(data == session.responseData)
    }

    @Test
    func rejectsNonHTTPResponse() async throws {
        let session = HTTPDataLoadingSpy(
            responseData: Data(),
            response: URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        )
        let error = try await failure(session: session)
        #expect(error.domain == "InvalidResponse")
        #expect(error.code == 500)
        #expect(error.localizedDescription == "Invalid response from server.")
    }

    @Test(arguments: [199, 300, 400, 500])
    func HTTPStatusFailureUsesJSONMessageBeforeContentTypeChecks(statusCode: Int) async throws {
        let error = try await failure(
            session: session(
                data: Data(#"{"message":"declined"}"#.utf8), statusCode: statusCode, headers: [:]
            ))
        #expect(error.domain == "HTTPError")
        #expect(error.code == statusCode)
        #expect(error.localizedDescription == "declined")
    }

    @Test(arguments: ["declined", #"{"message":42}"#, "[]", ""])
    func HTTPStatusFailureFallsBackToResponseText(text: String) async throws {
        let error = try await failure(session: session(data: Data(text.utf8), statusCode: 500))
        #expect(error.domain == "HTTPError")
        #expect(error.localizedDescription == text)
    }

    @Test
    func HTTPStatusFailureUsesInvalidUTF8Fallback() async throws {
        let error = try await failure(session: session(data: Data([0xFF]), statusCode: 500))
        #expect(error.domain == "HTTPError")
        #expect(error.localizedDescription == "Message is blank")
    }

    @Test(arguments: ["text/html", "", "APPLICATION/JSON"])
    func rejectsNonJSONContentTypeAndPreservesResponseBody(contentType: String) async throws {
        let text = "<html>Unavailable</html>"
        let error = try await failure(session: session(data: Data(text.utf8), headers: ["Content-Type": contentType]))
        #expect(error.domain == "InvalidContentType")
        #expect(error.code == 415)
        #expect(error.localizedDescription == "Server returned \(contentType) instead of JSON.")
        #expect(error.userInfo["responseBody"] as? String == text)
    }

    @Test
    func missingContentTypeUsesEmptyTypeInError() async throws {
        let error = try await failure(session: session(headers: [:]))
        #expect(error.domain == "InvalidContentType")
        #expect(error.code == 415)
        #expect(error.localizedDescription == "Server returned  instead of JSON.")
    }

    @Test
    func invalidUTF8NonJSONResponseUsesFallbackBody() async throws {
        let error = try await failure(session: session(data: Data([0xFF]), headers: [:]))
        #expect(error.domain == "InvalidContentType")
        #expect(error.userInfo["responseBody"] as? String == "Unable to decode response")
    }

    @Test(arguments: ["_Incapsula_Resource", "incap_ses"])
    func challengePreservesHTMLAndOriginalRequestURL(marker: String) async throws {
        let html = "<html>\(marker)</html>"
        let error = try await failure(session: session(data: Data(html.utf8), headers: ["Content-Type": "text/html"]))
        #expect(error.domain == NetworkChallengeConstants.domain)
        #expect(error.code == 403)
        #expect(error.localizedDescription == "Security challenge detected. User interaction required.")
        #expect(error.userInfo[NetworkChallengeConstants.htmlContentKey] as? String == html)
        #expect(error.userInfo[NetworkChallengeConstants.urlKey] as? String == url.absoluteString)
    }

    @Test
    func HTTPStatusFailureTakesPrecedenceOverChallengeDetection() async throws {
        let html = "<html>incap_ses</html>"
        let error = try await failure(session: session(data: Data(html.utf8), statusCode: 403, headers: [:]))
        #expect(error.domain == "HTTPError")
        #expect(error.code == 403)
        #expect(error.localizedDescription == html)
    }

    @Test
    func JSONContentTypeBypassesChallengeDetection() async throws {
        let session = session(data: Data(#"{"message":"incap_ses"}"#.utf8))
        let data = try await FoundationHTTPClient(session: session).request(HTTPRequest(url: url, method: .POST))
        #expect(data == session.responseData)
    }

    @Test
    func propagatesTransportFailureWithoutWrappingIt() async throws {
        let expectedError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
        let session = HTTPDataLoadingSpy(responseData: Data(), response: session().response, failure: expectedError)
        let error = try await failure(session: session)
        #expect(error === expectedError)
        #expect(session.request?.url == url)
    }

    @Test(arguments: [200, 400])
    func logsRequestAndHTTPResponseInOrderBeforeValidation(statusCode: Int) async throws {
        let session = session(statusCode: statusCode)
        let log = LogCapture()
        let expectedURL = url
        let body = Data("request-body".utf8)
        let client = FoundationHTTPClient(
            session: session,
            defaultHeaders: {
                log.record("headers")
                return ["User-Agent": "device"]
            },
            logRequest: { request, headers in
                #expect(session.request == nil)
                #expect(request.url == expectedURL)
                #expect(request.method == .PUT)
                #expect(request.body == body)
                #expect(headers == ["User-Agent": "device", "Cookie": "session=abc"])
                log.record("request")
            },
            logResponse: { url, response, data in
                #expect(session.request?.url == expectedURL)
                #expect(url == expectedURL)
                #expect(response.statusCode == statusCode)
                #expect(response.value(forHTTPHeaderField: "Content-Type") == "application/json")
                #expect(data == session.responseData)
                log.record("response")
            }
        )

        do {
            _ = try await client.request(HTTPRequest(url: url, method: .PUT, cookies: "session=abc", body: body))
            #expect(statusCode == 200)
        } catch {
            #expect(statusCode == 400)
            #expect((error as NSError).domain == "HTTPError")
        }
        #expect(log.recordedMessages == ["headers", "request", "response"])
    }

    @Test(arguments: [true, false])
    func logsOnlyRequestForTransportFailureOrNonHTTPResponse(transportFails: Bool) async throws {
        let expectedError = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)
        let session = HTTPDataLoadingSpy(
            responseData: Data(),
            response: URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil),
            failure: transportFails ? expectedError : nil
        )
        let log = LogCapture()
        let client = FoundationHTTPClient(
            session: session,
            logRequest: { _, _ in log.record("request") },
            logResponse: { _, _, _ in log.record("response") }
        )

        do {
            _ = try await client.request(HTTPRequest(url: url, method: .POST))
            Issue.record("Expected request to throw")
        } catch {
            if transportFails {
                #expect(error as NSError === expectedError)
            } else {
                #expect((error as NSError).domain == "InvalidResponse")
            }
        }
        #expect(log.recordedMessages == ["request"])
    }

    private func failure(session: HTTPDataLoadingSpy) async throws -> NSError {
        do {
            _ = try await FoundationHTTPClient(session: session).request(HTTPRequest(url: url, method: .POST))
            Issue.record("Expected request to throw")
            throw NSError(domain: "Test", code: 1)
        } catch {
            return error as NSError
        }
    }
}
