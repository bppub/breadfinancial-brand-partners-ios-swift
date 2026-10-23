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

enum MockServerKeys {
    /// Must match `APIBaseURLs.launchOverrideKey` in the BreadPartners SDK.
    static let baseURLKey = "BREAD_PARTNERS_MOCK_BASE_URL"
    static let resetState = "-UITestResetState"
}

/// Local HTTP/1.1 server, running in the UI test process on Network.framework, that the app
/// reaches through the SDK's DEBUG-only base URL override. Handles one request per connection.
/// Unmatched requests get `{}` with 200.
actor MockHTTPServer {
    private let listener: NWListener
    private let stubs: [HTTPStub]
    private let queue = DispatchQueue(label: "MockHTTPServer")
    private var paths: [String] = []

    init(stubs: [HTTPStub]) throws {
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: .any)
        self.listener = try NWListener(using: parameters)
        self.stubs = stubs
    }

    /// Starts listening on a free loopback port and returns the base URL to hand to the app.
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

    func stop() {
        listener.cancel()
    }

    /// Paths received so far, in arrival order.
    func receivedPaths() -> [String] {
        paths
    }

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

    private func respond(to request: RawHTTPRequest, on connection: NWConnection) {
        paths.append(request.path)

        let stub =
            stubs.first { request.path.contains($0.match) }
            ?? HTTPStub(match: "", jsonString: "{}")

        var head =
            "HTTP/1.1 \(stub.statusCode) \(HTTPURLResponse.localizedString(forStatusCode: stub.statusCode))\r\n"
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

/// A parsed request, or `nil` until the headers and the full body have arrived.
private struct RawHTTPRequest {
    let method: String
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
