//------------------------------------------------------------------------------
//  File:          StubURLProtocol.swift
//  Author(s):     Bread Financial
//
//  Description:   A custom URLProtocol used during UI testing to intercept the
//                 network traffic produced by the BreadPartners SDK (which runs
//                 on URLSession.shared) and return canned JSON responses.
//                 This lets UI tests run fully offline and deterministically.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Foundation

/// Intercepts `URLSession.shared` traffic and returns canned JSON for matching URLs.
///
/// The BreadPartners SDK resolves every request through `URLSession.shared`, which
/// consults globally-registered `URLProtocol` subclasses. Registering this class
/// therefore lets the host app serve stubbed responses without any SDK changes.
///
/// Matching is a simple substring test against the absolute request URL, which maps
/// directly to the API paths (e.g. `/config`, `/generatePlacements`, `/api/prescreen`).
final class StubURLProtocol: URLProtocol {

    /// A single canned response.
    struct Stub {
        let data: Data
        let statusCode: Int
        let headers: [String: String]
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var stubs: [(match: String, stub: Stub)] = []

    /// When `true`, any request that does not match a registered stub receives an
    /// empty `{}` 200 JSON response instead of hitting the real network. This keeps
    /// UI tests fully isolated (e.g. background analytics calls never leak out).
    nonisolated(unsafe) static var isolateUnmatchedRequests = true

    // MARK: - Registration

    /// Registers a stub for every request whose URL contains `match`.
    /// - Important: `headers` must contain `Content-Type: application/json`, otherwise
    ///   the SDK rejects the response with an `InvalidContentType` error.
    static func register(
        match: String,
        json: Data,
        statusCode: Int = 200,
        headers: [String: String] = ["Content-Type": "application/json"]
    ) {
        lock.lock(); defer { lock.unlock() }
        stubs.append((match, Stub(data: json, statusCode: statusCode, headers: headers)))
    }

    /// Removes all registered stubs.
    static func reset() {
        lock.lock(); defer { lock.unlock() }
        stubs.removeAll()
    }

    private static func stub(for url: URL) -> Stub? {
        lock.lock(); defer { lock.unlock() }
        return stubs.first { url.absoluteString.contains($0.match) }?.stub
    }

    // MARK: - URLProtocol

    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        if stub(for: url) != nil { return true }
        return isolateUnmatchedRequests
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "StubURLProtocol", code: -1))
            return
        }

        let resolved = Self.stub(for: url) ?? Stub(
            data: Data("{}".utf8),
            statusCode: 200,
            headers: ["Content-Type": "application/json"]
        )

        guard let response = HTTPURLResponse(
            url: url,
            statusCode: resolved.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: resolved.headers
        ) else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "StubURLProtocol", code: -2))
            return
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: resolved.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
