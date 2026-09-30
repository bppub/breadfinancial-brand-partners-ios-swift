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
    }

    @Test
    func requestAllowsNilBodyAndReturnsJSONData() async throws {
        let responseData = Data(#"{"result":"ok"}"#.utf8)
        let session = HTTPDataLoadingSpy(
            responseData: responseData,
            response: HTTPURLResponse(
                url: url,
                statusCode: 204,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json; charset=utf-8"]
            )!
        )

        let result = try await client(session: session).request(request())

        #expect(result == responseData)
        #expect(session.request?.httpBody == nil)
    }

    @Test
    func requestRejectsHTTPErrorUsingJSONMessage() async {
        let session = HTTPDataLoadingSpy(
            responseData: Data(#"{"message":"declined"}"#.utf8),
            response: HTTPURLResponse(
                url: url,
                statusCode: 400,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
        )

        await expectNSError(
            session: session,
            domain: "HTTPError",
            code: 400,
            containing: "declined"
        )
    }

    @Test
    func requestRejectsHTTPErrorUsingPlainTextAndInvalidUTF8Fallbacks() async {
        let session = HTTPDataLoadingSpy(
            responseData: Data("declined".utf8),
            response: HTTPURLResponse(
                url: url,
                statusCode: 500,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
        )
        await expectNSError(session: session, domain: "HTTPError", code: 500, containing: "declined")

        session.responseData = Data([0xFF])
        await expectNSError(session: session, domain: "HTTPError", code: 500, containing: "Message is blank")
    }

    @Test
    func requestRejectsNonHTTPResponse() async {
        let session = HTTPDataLoadingSpy(
            responseData: Data(),
            response: URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        )

        await expectNSError(session: session, domain: "InvalidResponse", code: 500, containing: "Invalid response")
    }

    @Test
    func requestRejectsIncapsulaChallenge() async {
        let session = HTTPDataLoadingSpy(
            responseData: Data("<html>incap_ses</html>".utf8),
            response: HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "text/html"]
            )!
        )

        await expectNSError(session: session, domain: "IncapsulaChallenge", code: 403, containing: "Security challenge")

        session.responseData = Data("<html>_Incapsula_Resource</html>".utf8)
        await expectNSError(session: session, domain: "IncapsulaChallenge", code: 403, containing: "Security challenge")
    }

    @Test
    func requestRejectsNonJSONContentIncludingMissingContentType() async {
        let session = HTTPDataLoadingSpy(
            responseData: Data("<html>Unavailable</html>".utf8),
            response: HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "text/html"]
            )!
        )
        await expectNSError(session: session, domain: "InvalidContentType", code: 415, containing: "text/html")

        session.responseData = Data([0xFF])
        await expectNSError(session: session, domain: "InvalidContentType", code: 415, containing: "Server returned")
    }

    @Test
    func requestRejectsResponseWithEmptyContentType() async {
        let session = HTTPDataLoadingSpy(
            responseData: Data("<html>Unavailable</html>".utf8),
            response: HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": ""]
            )!
        )

        await expectNSError(
            session: session,
            domain: "InvalidContentType",
            code: 415,
            containing: "Server returned  instead of JSON."
        )
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

    private func expectNSError(
        session: HTTPDataLoadingSpy,
        domain: String,
        code: Int,
        containing message: String
    ) async {
        do {
            _ = try await client(session: session).request(request())
            Issue.record("Expected request to throw")
        } catch let error as NSError {
            #expect(error.domain == domain)
            #expect(error.code == code)
            #expect(error.localizedDescription.contains(message))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
