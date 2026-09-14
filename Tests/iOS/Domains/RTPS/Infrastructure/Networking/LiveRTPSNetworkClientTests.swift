import BreadPartnersCore
import Foundation
import Testing
@testable import BreadPartners

@Suite struct LiveRTPSNetworkClientTests {
    @Test
    func sendsRequestAndConvertsJSONResponse() async throws {
        let responseData = Data(#"{"returnCode":"01","prescreenId":42}"#.utf8)
        NetworkURLProtocol.response = (responseData, 200, ["Content-Type": "application/json"])
        NetworkURLProtocol.reset()
        URLProtocol.registerClass(NetworkURLProtocol.self)
        defer {
            URLProtocol.unregisterClass(NetworkURLProtocol.self)
            NetworkURLProtocol.reset()
        }

        let requestBody = Data(#"{"prescreenId":"42"}"#.utf8)
        let request = RTPSNetworkRequest(
            url: URL(string: "https://example.com/rtps")!,
            method: .post,
            headers: ["X-Client-Key": "integration-key"],
            cookies: "session=abc",
            body: requestBody
        )

        let response = try await LiveRTPSNetworkClient(logger: Logger()).send(request)

        #expect(response.data == responseData)
        #expect(response.statusCode == 200)
        #expect(NetworkURLProtocol.lastRequest?.url?.absoluteString == "https://example.com/rtps")
        #expect(NetworkURLProtocol.lastRequest?.httpMethod == "POST")
        #expect(NetworkURLProtocol.lastRequest?.value(forHTTPHeaderField: "X-Client-Key") == "integration-key")
        #expect(NetworkURLProtocol.lastRequest?.value(forHTTPHeaderField: "Cookie") == "session=abc")
        #expect(NetworkURLProtocol.lastBody == requestBody)
    }

    @Test
    func sendsRequestWithoutBody() async throws {
        NetworkURLProtocol.response = (Data(#"{"ok":true}"#.utf8), 200, ["Content-Type": "application/json"])
        NetworkURLProtocol.reset()
        URLProtocol.registerClass(NetworkURLProtocol.self)
        defer {
            URLProtocol.unregisterClass(NetworkURLProtocol.self)
            NetworkURLProtocol.reset()
        }

        let request = RTPSNetworkRequest(
            url: URL(string: "https://example.com/rtps")!,
            method: .get
        )

        _ = try await LiveRTPSNetworkClient(logger: Logger()).send(request)

        #expect(NetworkURLProtocol.lastRequest?.httpMethod == "GET")
        #expect(NetworkURLProtocol.lastBody == nil)
    }
}

private final class NetworkURLProtocol: URLProtocol {
    nonisolated(unsafe) static var response: (Data, Int, [String: String]) = (Data(), 200, [:])
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
        Self.lastBody = request.httpBody

        let (data, statusCode, headers) = Self.response
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
        lastRequest = nil
        lastBody = nil
    }
}
