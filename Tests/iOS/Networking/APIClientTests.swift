import Foundation
import Testing
@testable import BreadPartners

@Suite(.serialized) struct APIClientTests {
    private struct TestPayload: Encodable {
        let value: Int
    }

    private func client() -> APIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [APIClientURLProtocol.self]
        return APIClient(
            logger: Logger(),
            session: URLSession(configuration: configuration)
        )
    }

    @Test
    func requestDataSendsRequestAndReturnsData() async throws {
        let responseData = Data(#"{"ok":true}"#.utf8)
        APIClientURLProtocol.reset()
        APIClientURLProtocol.response = (responseData, 200, ["Content-Type": "application/json"])
        defer {
            APIClientURLProtocol.reset()
        }

        let body = Data(#"{"value":42}"#.utf8)
        let result = try await client().requestData(
            urlString: "https://example.com/api",
            method: .PUT,
            headers: ["X-Test": "value", "Content-Type": "text/plain"],
            cookies: "session=abc",
            body: body
        )

        #expect(result == responseData)
        #expect(APIClientURLProtocol.lastRequest?.httpMethod == "PUT")
        #expect(APIClientURLProtocol.lastRequest?.value(forHTTPHeaderField: "X-Test") == "value")
        #expect(APIClientURLProtocol.lastRequest?.value(forHTTPHeaderField: "Content-Type") == "text/plain")
        #expect(APIClientURLProtocol.lastRequest?.value(forHTTPHeaderField: "Cookie") == "session=abc")
        #expect(APIClientURLProtocol.lastBody == body)
    }

    @Test
    func requestPreservesDataBodyAndDecodesJSON() async throws {
        let responseData = Data(#"{"result":"ok"}"#.utf8)
        APIClientURLProtocol.reset()
        APIClientURLProtocol.response = (responseData, 200, ["Content-Type": "application/json"])
        defer {
            APIClientURLProtocol.reset()
        }

        let body = Data(#"{"raw":true}"#.utf8)
        let result = try await client().request(
            urlString: "https://example.com/api",
            body: AnySendable(value: body)
        )

        #expect((result.value as? [String: String])?["result"] == "ok")
        #expect(APIClientURLProtocol.lastBody == body)
    }

    @Test
    func requestEncodesDictionaryBody() async throws {
        let responseData = Data(#"{"ok":true}"#.utf8)
        APIClientURLProtocol.reset()
        APIClientURLProtocol.response = (responseData, 200, ["Content-Type": "application/json"])
        defer {
            APIClientURLProtocol.reset()
        }

        _ = try await client().request(
            urlString: "https://example.com/api",
            body: ["value": 42]
        )

        let body = try #require(APIClientURLProtocol.lastBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Int])
        #expect(json["value"] == 42)
    }

    @Test
    func requestEncodesCodableBody() async throws {
        let responseData = Data(#"{"ok":true}"#.utf8)
        APIClientURLProtocol.reset()
        APIClientURLProtocol.response = (responseData, 200, ["Content-Type": "application/json"])
        defer { APIClientURLProtocol.reset() }

        _ = try await client().request(
            urlString: "https://example.com/api",
            body: TestPayload(value: 42)
        )

        let body = try #require(APIClientURLProtocol.lastBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Int])
        #expect(json["value"] == 42)
    }

    @Test
    func requestRejectsUnsupportedBodyType() async {
        do {
            _ = try await client().request(
                urlString: "https://example.com/api",
                body: NSObject()
            )
            Issue.record("Expected unsupported body type to throw")
        } catch let error as NSError {
            #expect(error.domain == "SerializationError")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func requestDataRejectsInvalidURL() async {
        do {
            _ = try await client().requestData(urlString: "https://[")
            Issue.record("Expected invalid URL to throw")
        } catch let error as NSError {
            #expect(error.domain == "InvalidURL")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func requestDataRejectsHTTPErrorWithServerMessage() async {
        APIClientURLProtocol.reset()
        APIClientURLProtocol.response = (
            Data(#"{"message":"declined"}"#.utf8), 400, ["Content-Type": "application/json"]
        )
        defer {
            APIClientURLProtocol.reset()
        }

        do {
            _ = try await client().requestData(urlString: "https://example.com/api")
            Issue.record("Expected HTTP error to throw")
        } catch let error as NSError {
            #expect(error.domain == "HTTPError")
            #expect(error.code == 400)
            #expect(error.localizedDescription.contains("declined"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func requestDataRejectsHTTPErrorWithPlainTextMessage() async {
        APIClientURLProtocol.reset()
        APIClientURLProtocol.response = (Data("declined".utf8), 400, ["Content-Type": "application/json"])
        defer { APIClientURLProtocol.reset() }

        do {
            _ = try await client().requestData(urlString: "https://example.com/api")
            Issue.record("Expected HTTP error to throw")
        } catch let error as NSError {
            #expect(error.domain == "HTTPError")
            #expect(error.localizedDescription.contains("declined"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func requestDataRejectsHTTPErrorWithInvalidUTF8Message() async {
        APIClientURLProtocol.reset()
        APIClientURLProtocol.response = (Data([0xFF]), 400, ["Content-Type": "application/json"])
        defer { APIClientURLProtocol.reset() }

        do {
            _ = try await client().requestData(urlString: "https://example.com/api")
            Issue.record("Expected HTTP error to throw")
        } catch let error as NSError {
            #expect(error.domain == "HTTPError")
            #expect(error.localizedDescription.contains("Message is blank"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func requestDataRejectsIncapsulaChallenge() async {
        APIClientURLProtocol.reset()
        APIClientURLProtocol.response = (
            Data("<html>_Incapsula_Resource</html>".utf8), 200, ["Content-Type": "text/html"]
        )
        defer {
            APIClientURLProtocol.reset()
        }

        do {
            _ = try await client().requestData(urlString: "https://example.com/api")
            Issue.record("Expected challenge response to throw")
        } catch let error as NSError {
            #expect(error.domain == "IncapsulaChallenge")
            #expect(error.code == 403)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func requestRejectsInvalidJSONResponse() async {
        APIClientURLProtocol.reset()
        APIClientURLProtocol.response = (Data("not-json".utf8), 200, ["Content-Type": "application/json"])
        defer {
            APIClientURLProtocol.reset()
        }

        do {
            _ = try await client().request(urlString: "https://example.com/api")
            Issue.record("Expected invalid JSON to throw")
        } catch let error as NSError {
            #expect(error.domain == "DecodingError")
            #expect(error.code == 500)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func requestDataRejectsNonJSONResponse() async {
        APIClientURLProtocol.reset()
        APIClientURLProtocol.response = (Data("<html>Unavailable</html>".utf8), 200, ["Content-Type": "text/html"])
        defer { APIClientURLProtocol.reset() }

        do {
            _ = try await client().requestData(urlString: "https://example.com/api")
            Issue.record("Expected invalid content type to throw")
        } catch let error as NSError {
            #expect(error.domain == "InvalidContentType")
            #expect(error.code == 415)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func requestDataRejectsResponseWithoutContentType() async {
        APIClientURLProtocol.reset()
        APIClientURLProtocol.response = (Data("<html>Unavailable</html>".utf8), 200, [:])
        defer { APIClientURLProtocol.reset() }

        do {
            _ = try await client().requestData(urlString: "https://example.com/api")
            Issue.record("Expected missing content type to throw")
        } catch let error as NSError {
            #expect(error.domain == "InvalidContentType")
            #expect(error.code == 415)
            #expect(error.localizedDescription.contains("Server returned  instead of JSON."))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func requestDataUsesFallbackForNonUTF8NonJSONResponse() async {
        APIClientURLProtocol.reset()
        APIClientURLProtocol.response = (Data([0xFF]), 200, ["Content-Type": "text/html"])
        defer { APIClientURLProtocol.reset() }

        do {
            _ = try await client().requestData(urlString: "https://example.com/api")
            Issue.record("Expected invalid content type to throw")
        } catch let error as NSError {
            #expect(error.domain == "InvalidContentType")
            #expect(error.code == 415)
            #expect(error.userInfo["responseBody"] as? String == "Unable to decode response")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func requestDataRejectsNonHTTPResponse() async {
        APIClientURLProtocol.reset()
        APIClientURLProtocol.returnsNonHTTPResponse = true
        defer { APIClientURLProtocol.reset() }

        do {
            _ = try await client().requestData(urlString: "https://example.com/api")
            Issue.record("Expected invalid response to throw")
        } catch let error as NSError {
            #expect(error.domain == "InvalidResponse")
            #expect(error.code == 500)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func requestRejectsValidNonDictionaryJSONResponse() async {
        APIClientURLProtocol.reset()
        APIClientURLProtocol.response = (Data("[]".utf8), 200, ["Content-Type": "application/json"])
        defer { APIClientURLProtocol.reset() }

        do {
            _ = try await client().request(urlString: "https://example.com/api")
            Issue.record("Expected non-dictionary JSON to throw")
        } catch let error as NSError {
            #expect(error.domain == "DecodingError")
            #expect(error.code == 500)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

private final class APIClientURLProtocol: URLProtocol {
    nonisolated(unsafe) static var response: (Data, Int, [String: String]) = (Data(), 200, [:])
    nonisolated(unsafe) static var returnsNonHTTPResponse = false
    nonisolated(unsafe) static var lastRequest: URLRequest?
    nonisolated(unsafe) static var lastBody: Data?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

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
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: headers
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
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
