import Foundation

/// Intercepts URLSession traffic (including `URLSession.shared`, which the SDK
/// uses by default) and returns canned responses registered via `stub(...)`.
///
/// Register globally with `MockURLProtocol.register()` so it reaches the SDK's
/// default session, then install stubs per test. Call `unregister()` in
/// `tearDown` to clear state and avoid cross-test leakage.
final class MockURLProtocol: URLProtocol {

    struct Stub {
        let statusCode: Int
        let data: Data
        let headers: [String: String]
        let error: Error?
    }

    /// Matcher closure -> stub. First match wins.
    nonisolated(unsafe) private static var stubs: [(match: (URLRequest) -> Bool, stub: Stub)] = []
    nonisolated(unsafe) private(set) static var capturedRequests: [URLRequest] = []
    private static let lock = NSLock()

    // MARK: Registration API

    static func register() {
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    static func unregister() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        reset()
    }

    static func reset() {
        lock.lock(); defer { lock.unlock() }
        stubs.removeAll()
        capturedRequests.removeAll()
    }

    static func stub(
        where match: @escaping (URLRequest) -> Bool,
        statusCode: Int = 200,
        data: Data,
        headers: [String: String] = ["Content-Type": "application/json"],
        error: Error? = nil
    ) {
        lock.lock(); defer { lock.unlock() }
        stubs.append((match, Stub(statusCode: statusCode, data: data, headers: headers, error: error)))
    }

    /// Convenience: match by path suffix so stubs survive stage/prod/uat host switches.
    static func stub(
        path: String,
        statusCode: Int = 200,
        json: String
    ) {
        stub(
            where: { $0.url?.path.hasSuffix(path) ?? false },
            statusCode: statusCode,
            data: Data(json.utf8)
        )
    }

    // MARK: URLProtocol

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lock.lock()
        Self.capturedRequests.append(request)
        let match = Self.stubs.first { $0.match(request) }?.stub
        Self.lock.unlock()

        guard let stub = match else {
            // Fail loudly so unstubbed traffic doesn't silently hit the network.
            let err = NSError(
                domain: "MockURLProtocol",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey:
                    "Unstubbed request: \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "?")"]
            )
            client?.urlProtocol(self, didFailWithError: err)
            return
        }

        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: stub.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: stub.headers
        )!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
