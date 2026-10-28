//------------------------------------------------------------------------------
//  File:          MockHTTPServer.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Foundation
import Network

/// Names shared by the UI tests and the test app. They run as separate processes,
/// so these strings are how the tests pass settings to the app at launch.
enum MockServerKeys {
    /// Launch environment variable holding the mock server's URL, e.g. `http://127.0.0.1:52341`.
    /// In DEBUG builds the SDK sends its requests there instead of to the real backend.
    /// Must match `APIBaseURLs.launchOverrideKey` in the BreadPartners SDK.
    static let baseURLKey = "BREAD_PARTNERS_MOCK_BASE_URL"
}

/// A tiny fake backend that runs inside the UI test process.
///
/// UI tests must not call the real Bread Financial services, so the test starts this server on
/// the local machine and tells the app to talk to it instead (see `MockServerKeys.baseURLKey`).
/// The server answers each request with the first stub whose `match` text appears in the request
/// path, and records every path it receives so a test can assert the app really made the call.
///
/// ```swift
/// let server = try MockHTTPServer(stubs: [Fixtures.Placements.pala])
/// let baseURL = try await server.start()
///
/// let app = XCUIApplication()
/// app.launchEnvironment[MockServerKeys.baseURLKey] = baseURL.absoluteString
/// app.launchFresh()
/// // ... drive the UI ...
/// let paths = await server.receivedPaths()   // e.g. ["/generatePlacements"]
/// await server.stop()
/// ```
///
/// It speaks just enough HTTP/1.1 for the SDK: one request per connection, and the connection is
/// closed after the response. Requests that match no stub get `{}` with status 200.
actor MockHTTPServer {
    private let listener: NWListener
    private let stubs: [MockHttpResponse]
    private let queue = DispatchQueue(label: "MockHTTPServer", qos: .userInteractive)
    private var paths: [String] = []

    /// Creates the server but does not start it; call `start()` to begin listening.
    /// - Parameter stubs: Canned responses, checked in order. The first whose `match` is contained
    ///   in the request path wins, so list more specific matches first.
    /// - Throws: If the system can't create a listener on the loopback interface.
    init(stubs: [MockHttpResponse]) throws {
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: .any)
        self.listener = try NWListener(using: parameters)
        self.stubs = stubs
    }

    /// Starts listening on a free loopback port and returns the base URL to give to the app.
    ///
    /// The system picks the port, so parallel tests never collide. The URL has no trailing slash,
    /// e.g. `http://127.0.0.1:52341`.
    /// - Throws: If the listener fails to start.
    func start() async throws -> URL {
        let queue = queue
        listener.newConnectionHandler = { [weak self] connection in
            connection.start(queue: queue)
            self?.receive(on: connection, buffer: Data())
        }

        let listener = listener
        let port: UInt16 = try await withCheckedThrowingContinuation { continuation in
            listener.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    listener.stateUpdateHandler = nil
                    continuation.resume(returning: listener.port?.rawValue ?? 0)
                case let .failed(error):
                    listener.stateUpdateHandler = nil
                    continuation.resume(throwing: error)
                case .cancelled:
                    listener.stateUpdateHandler = nil
                    continuation.resume(throwing: CancellationError())
                default:
                    break
                }
            }
            listener.start(queue: queue)
        }
        return URL(string: "http://127.0.0.1:\(port)")!
    }

    /// Stops accepting new connections. Call this in `tearDown` so the port is released.
    func stop() {
        listener.cancel()
    }

    /// Request paths received so far, oldest first, without query strings
    /// (`/config?x=1` is recorded as `/config`). Use it to assert the app called an endpoint.
    func receivedPaths() -> [String] {
        paths
    }

    /// Reads from the connection until a whole request has arrived, then answers it.
    /// Data can arrive in pieces, so what has been read so far is carried along in `buffer`.
    private nonisolated func receive(on connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) {
            [weak self] data, _, isComplete, error in
            guard let self else { return connection.cancel() }
            var buffer = buffer
            if let data { buffer.append(data) }

            if let request = RawHTTPRequest(buffer) {
                Task { await self.respond(to: request, on: connection) }
            } else if isComplete || error != nil {
                connection.cancel()
            } else {
                self.receive(on: connection, buffer: buffer)
            }
        }
    }

    /// Records the request, picks the matching stub (or `{}` if none match), writes the response,
    /// and closes the connection.
    private func respond(to request: RawHTTPRequest, on connection: NWConnection) {
        paths.append(request.path)

        let stub =
            stubs.first { request.path.contains($0.match) }
            ?? MockHttpResponse(match: "", jsonString: "{}")

        var head =
            "HTTP/1.1 \(stub.statusCode) \(HTTPURLResponse.localizedString(forStatusCode: stub.statusCode))\r\n"
        // The server sets the real length, so a stub's own Content-Length header is dropped.
        for (name, value) in stub.headers where name.caseInsensitiveCompare("Content-Length") != .orderedSame {
            head += "\(name): \(value)\r\n"
        }
        head += "Content-Length: \(stub.json.count)\r\nConnection: close\r\n\r\n"

        connection.send(
            content: Data(head.utf8) + stub.json,
            completion: .contentProcessed { _ in connection.cancel() }
        )
    }
}

/// The parts of an incoming HTTP request the server needs: method, path and body.
///
/// The initializer returns `nil` while the request is still incomplete, meaning the headers have
/// not fully arrived or fewer than `Content-Length` body bytes have. The caller keeps reading
/// and tries again with the larger buffer.
private struct RawHTTPRequest {
    let method: String
    /// The URL path only; any `?query` part is removed.
    let path: String
    let body: Data

    init?(_ data: Data) {
        guard
            let headerEnd = data.range(of: Data("\r\n\r\n".utf8)),
            let head = String(data: data[..<headerEnd.lowerBound], encoding: .utf8)
        else { return nil }

        let lines = head.components(separatedBy: "\r\n")
        let requestLine = lines.first?.split(separator: " ") ?? []
        guard requestLine.count >= 2 else { return nil }

        let contentLength =
            lines.dropFirst()
            .first { $0.lowercased().hasPrefix("content-length:") }
            .flatMap { Int($0.dropFirst("content-length:".count).trimmingCharacters(in: .whitespaces)) }
            ?? 0

        let body = data[headerEnd.upperBound...]
        guard body.count >= contentLength else { return nil }

        self.method = String(requestLine[0])
        self.path = String(requestLine[1].split(separator: "?", maxSplits: 1)[0])
        self.body = Data(body.prefix(contentLength))
    }
}
