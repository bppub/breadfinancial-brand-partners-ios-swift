import Foundation
import Testing
@testable import BreadPartners

@Suite(.serialized) struct LiveHTTPClientTests {
    private let url = URL(string: "https://example.com/api")!

    private func client() -> LiveHTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [LiveHTTPClientURLProtocol.self]
        return LiveHTTPClient(
            logger: Logger(),
            session: URLSession(configuration: configuration)
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
        LiveHTTPClientURLProtocol.reset()
        LiveHTTPClientURLProtocol.response = (responseData, 200, ["Content-Type": "application/json"])
        defer { LiveHTTPClientURLProtocol.reset() }

        let body = Data(#"{"value":42}"#.utf8)
        let result = try await client().request(
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
        #expect(LiveHTTPClientURLProtocol.lastRequest?.url == url)
        #expect(LiveHTTPClientURLProtocol.lastRequest?.httpMethod == "PUT")
        #expect(LiveHTTPClientURLProtocol.lastRequest?.value(forHTTPHeaderField: "X-Test") == "value")
        #expect(LiveHTTPClientURLProtocol.lastRequest?.value(forHTTPHeaderField: "Content-Type") == "text/plain")
        #expect(LiveHTTPClientURLProtocol.lastRequest?.value(forHTTPHeaderField: "Cookie") == "session=abc")
        #expect(LiveHTTPClientURLProtocol.lastBody == body)
        #expect(LiveHTTPClientURLProtocol.lastRequest?.value(forHTTPHeaderField: Constants.headerOriginKey) == Constants.headerOriginValue)
        #expect(LiveHTTPClientURLProtocol.lastRequest?.value(forHTTPHeaderField: Constants.headerPlatformKey) == Constants.headerPlatformValue)
    }

    @Test
    func requestAllowsNilBodyAndReturnsJSONData() async throws {
        let responseData = Data(#"{"result":"ok"}"#.utf8)
        LiveHTTPClientURLProtocol.reset()
        LiveHTTPClientURLProtocol.response = (responseData, 204, ["Content-Type": "application/json; charset=utf-8"])
        defer { LiveHTTPClientURLProtocol.reset() }

        let result = try await client().request(request())

        #expect(result == responseData)
        #expect(LiveHTTPClientURLProtocol.lastBody == nil)
    }

    @Test
    func requestRejectsHTTPErrorUsingJSONMessage() async {
        LiveHTTPClientURLProtocol.reset()
        LiveHTTPClientURLProtocol.response = (Data(#"{"message":"declined"}"#.utf8), 400, ["Content-Type": "application/json"])
        defer { LiveHTTPClientURLProtocol.reset() }

        await expectNSError(domain: "HTTPError", code: 400, containing: "declined")
    }

    @Test
    func requestRejectsHTTPErrorUsingPlainTextAndInvalidUTF8Fallbacks() async {
        LiveHTTPClientURLProtocol.reset()
        LiveHTTPClientURLProtocol.response = (Data("declined".utf8), 500, ["Content-Type": "application/json"])
        defer { LiveHTTPClientURLProtocol.reset() }
        await expectNSError(domain: "HTTPError", code: 500, containing: "declined")

        LiveHTTPClientURLProtocol.response = (Data([0xFF]), 500, ["Content-Type": "application/json"])
        await expectNSError(domain: "HTTPError", code: 500, containing: "Message is blank")
    }

    @Test
    func requestRejectsNonHTTPResponse() async {
        LiveHTTPClientURLProtocol.reset()
        LiveHTTPClientURLProtocol.returnsNonHTTPResponse = true
        defer { LiveHTTPClientURLProtocol.reset() }

        await expectNSError(domain: "InvalidResponse", code: 500, containing: "Invalid response")
    }

    @Test
    func requestRejectsIncapsulaChallenge() async {
        LiveHTTPClientURLProtocol.reset()
        LiveHTTPClientURLProtocol.response = (Data("<html>incap_ses</html>".utf8), 200, ["Content-Type": "text/html"])
        defer { LiveHTTPClientURLProtocol.reset() }

        await expectNSError(domain: "IncapsulaChallenge", code: 403, containing: "Security challenge")
    }

    @Test
    func requestRejectsNonJSONContentIncludingMissingContentType() async {
        LiveHTTPClientURLProtocol.reset()
        LiveHTTPClientURLProtocol.response = (Data("<html>Unavailable</html>".utf8), 200, ["Content-Type": "text/html"])
        defer { LiveHTTPClientURLProtocol.reset() }
        await expectNSError(domain: "InvalidContentType", code: 415, containing: "text/html")

        LiveHTTPClientURLProtocol.response = (Data([0xFF]), 200, [:])
        await expectNSError(domain: "InvalidContentType", code: 415, containing: "Server returned")
    }

    private func expectNSError(
        domain: String,
        code: Int,
        containing message: String
    ) async {
        do {
            _ = try await client().request(request())
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

private final class LiveHTTPClientURLProtocol: URLProtocol {
    nonisolated(unsafe) static var response: (Data, Int, [String: String]) = (Data(), 200, [:])
    nonisolated(unsafe) static var returnsNonHTTPResponse = false
    nonisolated(unsafe) static var lastRequest: URLRequest?
    nonisolated(unsafe) static var lastBody: Data?

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        if let body = request.httpBody {
            Self.lastBody = body
        } else if let bodyStream = request.httpBodyStream {
            bodyStream.open()
            defer { bodyStream.close() }

            var body = Data()
            var buffer = [UInt8](repeating: 0, count: 1024)
            while bodyStream.hasBytesAvailable {
                let bytesRead = bodyStream.read(&buffer, maxLength: buffer.count)
                guard bytesRead > 0 else { break }
                body.append(buffer, count: bytesRead)
            }
            Self.lastBody = body
        } else {
            Self.lastBody = nil
        }
        let (data, statusCode, headers) = Self.response

        if Self.returnsNonHTTPResponse {
            let response = URLResponse(
                url: request.url!,
                mimeType: nil,
                expectedContentLength: data.count,
                textEncodingName: nil
            )
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        } else {
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: headers
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }

        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    static func reset() {
        response = (Data(), 200, [:])
        returnsNonHTTPResponse = false
        lastRequest = nil
        lastBody = nil
    }
}