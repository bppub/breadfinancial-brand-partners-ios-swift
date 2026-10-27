//------------------------------------------------------------------------------
//  File:          MockHTTPServerTests.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Network
import XCTest

@MainActor
final class MockHTTPServerTests: XCTestCase {
    private var servers: [MockHTTPServer] = []

    private let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 5
        return URLSession(configuration: configuration)
    }()

    override func tearDown() async throws {
        for server in servers {
            await server.stop()
        }
        servers = []
        try await super.tearDown()
    }

    // MARK: - Lifecycle

    func testStartReturnsLoopbackBaseURLWithAPort() async throws {
        let (_, baseURL) = try await startServer(stubs: [])

        XCTAssertEqual(baseURL.scheme, "http")
        XCTAssertEqual(baseURL.host, "127.0.0.1")
        XCTAssertGreaterThan(try XCTUnwrap(baseURL.port), 0)
    }

    func testEachServerGetsItsOwnPort() async throws {
        let (_, first) = try await startServer(stubs: [])
        let (_, second) = try await startServer(stubs: [])

        XCTAssertNotEqual(first.port, second.port)
    }

    func testStopRefusesNewConnections() async throws {
        let (server, baseURL) = try await startServer(stubs: [])
        _ = try await send("/ping", to: baseURL)

        await server.stop()

        var refused = false
        for _ in 0..<20 {
            do {
                _ = try await send("/ping", to: baseURL)
            } catch {
                refused = true
                break
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertTrue(refused, "Server should stop accepting connections after stop()")
    }

    // MARK: - Stub matching

    func testMatchedStubReturnsItsBodyStatusAndHeaders() async throws {
        let stub = MockHttpResponse(
            match: "/config",
            jsonString: #"{ "brandId": "test-brand" }"#,
            headers: ["Content-Type": "application/json", "X-Test": "yes"]
        )
        let (_, baseURL) = try await startServer(stubs: [stub])

        let (data, response) = try await send("/brands/abc/config", to: baseURL)

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(data, stub.json)
        XCTAssertEqual(response.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(response.value(forHTTPHeaderField: "X-Test"), "yes")
    }

    func testUnmatchedRequestReturnsEmptyJSONObject() async throws {
        let (_, baseURL) = try await startServer(stubs: [
            MockHttpResponse(match: "/config", jsonString: #"{ "a": 1 }"#)
        ])

        let (data, response) = try await send("/something-else", to: baseURL)

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(String(decoding: data, as: UTF8.self), "{}")
    }

    func testFirstMatchingStubWins() async throws {
        let (_, baseURL) = try await startServer(stubs: [
            MockHttpResponse(match: "/generatePlacements", jsonString: #"{ "stub": "first" }"#),
            MockHttpResponse(match: "/generate", jsonString: #"{ "stub": "second" }"#),
        ])

        let (data, _) = try await send("/generatePlacements", to: baseURL)

        XCTAssertEqual(String(decoding: data, as: UTF8.self), #"{ "stub": "first" }"#)
    }

    func testNonSuccessStatusCodeIsReturned() async throws {
        let (_, baseURL) = try await startServer(stubs: [
            MockHttpResponse(match: "/fail", jsonString: #"{ "error": "boom" }"#, statusCode: 500)
        ])

        let (data, response) = try await send("/fail", to: baseURL)

        XCTAssertEqual(response.statusCode, 500)
        XCTAssertEqual(String(decoding: data, as: UTF8.self), #"{ "error": "boom" }"#)
    }

    func testStubContentLengthHeaderIsReplacedWithTheRealLength() async throws {
        let stub = MockHttpResponse(
            match: "/length",
            jsonString: #"{ "ok": true }"#,
            headers: ["content-length": "999", "Content-Type": "application/json"]
        )
        let (_, baseURL) = try await startServer(stubs: [stub])

        let (data, response) = try await send("/length", to: baseURL)

        XCTAssertEqual(data, stub.json)
        XCTAssertEqual(response.value(forHTTPHeaderField: "Content-Length"), String(stub.json.count))
    }

    // MARK: - Request handling

    func testReceivedPathsAreRecordedInArrivalOrderWithoutQueryStrings() async throws {
        let (server, baseURL) = try await startServer(stubs: [])

        _ = try await send("/first", to: baseURL)
        _ = try await send("/second?brand=1&x=2", to: baseURL)
        _ = try await send("/third", to: baseURL)

        let paths = await server.receivedPaths()
        XCTAssertEqual(paths, ["/first", "/second", "/third"])
    }

    func testStubsMatchOnThePathAndNotTheQueryString() async throws {
        let (_, baseURL) = try await startServer(stubs: [
            MockHttpResponse(match: "/config", jsonString: #"{ "stub": true }"#)
        ])

        let (matched, _) = try await send("/config?x=1", to: baseURL)
        let (unmatched, _) = try await send("/other?next=/config", to: baseURL)

        XCTAssertEqual(String(decoding: matched, as: UTF8.self), #"{ "stub": true }"#)
        XCTAssertEqual(String(decoding: unmatched, as: UTF8.self), "{}")
    }

    func testPostRequestWithBodyIsAnswered() async throws {
        let (server, baseURL) = try await startServer(stubs: [
            MockHttpResponse(match: "/ep/v1/view-placement", jsonString: #"{ "ok": true }"#)
        ])
        let body = Data(String(repeating: "x", count: 10_000).utf8)

        let (data, response) = try await send("/ep/v1/view-placement", method: "POST", body: body, to: baseURL)

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(String(decoding: data, as: UTF8.self), #"{ "ok": true }"#)
        let paths = await server.receivedPaths()
        XCTAssertEqual(paths, ["/ep/v1/view-placement"])
    }

    func testResponseAsksTheClientToCloseTheConnection() async throws {
        let (_, baseURL) = try await startServer(stubs: [])

        let (_, response) = try await send("/ping", to: baseURL)

        XCTAssertEqual(response.value(forHTTPHeaderField: "Connection")?.lowercased(), "close")
    }

    func testServesManyConcurrentRequests() async throws {
        let (server, baseURL) = try await startServer(stubs: [
            MockHttpResponse(match: "/ping", jsonString: #"{ "pong": true }"#)
        ])

        try await withThrowingTaskGroup(of: Int.self) { group in
            for index in 0..<10 {
                group.addTask { [self] in
                    try await self.send("/ping?i=\(index)", to: baseURL).response.statusCode
                }
            }
            for try await status in group {
                XCTAssertEqual(status, 200)
            }
        }

        let paths = await server.receivedPaths()
        XCTAssertEqual(paths.count, 10)
    }

    // MARK: - Incremental requests

    func testWaitsForTheCompleteHeadersBeforeResponding() async throws {
        let (server, baseURL) = try await startServer(stubs: [
            MockHttpResponse(match: "/split", jsonString: #"{ "ok": true }"#)
        ])
        let client = RawClient(port: try XCTUnwrap(baseURL.port))
        try await client.connect()

        client.send("GET /split HTTP/1.1\r\nHost: localhost\r\n")
        try await Task.sleep(nanoseconds: 300_000_000)
        let pathsBeforeHeadersEnd = await server.receivedPaths()
        XCTAssertTrue(pathsBeforeHeadersEnd.isEmpty, "Server must not respond to partial headers")

        client.send("\r\n")
        let response = await client.readToEnd()

        XCTAssertTrue(response.hasPrefix("HTTP/1.1 200"), response)
        XCTAssertTrue(response.hasSuffix(#"{ "ok": true }"#), response)
    }

    func testWaitsForTheFullBodyBeforeResponding() async throws {
        let (server, baseURL) = try await startServer(stubs: [
            MockHttpResponse(match: "/upload", jsonString: #"{ "ok": true }"#)
        ])
        let client = RawClient(port: try XCTUnwrap(baseURL.port))
        try await client.connect()

        client.send("POST /upload HTTP/1.1\r\nHost: localhost\r\nContent-Length: 5\r\n\r\nhe")
        try await Task.sleep(nanoseconds: 300_000_000)
        let pathsBeforeBodyEnds = await server.receivedPaths()
        XCTAssertTrue(pathsBeforeBodyEnds.isEmpty, "Server must wait for Content-Length bytes")

        client.send("llo")
        let response = await client.readToEnd()

        XCTAssertTrue(response.hasPrefix("HTTP/1.1 200"), response)
        let pathsAfterBody = await server.receivedPaths()
        XCTAssertEqual(pathsAfterBody, ["/upload"])
    }

    // MARK: - Helpers

    private func startServer(
        stubs: [MockHttpResponse]
    ) async throws -> (server: MockHTTPServer, baseURL: URL) {
        let server = try MockHTTPServer(stubs: stubs)
        servers.append(server)
        return (server, try await server.start())
    }

    private func send(
        _ path: String,
        method: String = "GET",
        body: Data? = nil,
        to baseURL: URL
    ) async throws -> (data: Data, response: HTTPURLResponse) {
        var request = URLRequest(url: try XCTUnwrap(URL(string: baseURL.absoluteString + path)))
        request.httpMethod = method
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        return (data, try XCTUnwrap(response as? HTTPURLResponse))
    }
}

final class MockServerKeysTests: XCTestCase {
    func testBaseURLKeyMatchesTheSDKLaunchOverrideKey() {
        XCTAssertEqual(MockServerKeys.baseURLKey, "BREAD_PARTNERS_MOCK_BASE_URL")
    }

    func testResetStateIsALaunchArgument() {
        XCTAssertEqual(MockServerKeys.resetState, "-UITestResetState")
    }
}

/// Plain TCP client for sending a request in pieces, which `URLSession` can't do.
private final class RawClient: @unchecked Sendable {
    private let connection: NWConnection
    private let queue = DispatchQueue(label: "RawClient")

    init(port: Int) {
        connection = NWConnection(
            host: "127.0.0.1",
            port: NWEndpoint.Port(rawValue: UInt16(port))!,
            using: .tcp
        )
    }

    func connect() async throws {
        let connection = connection
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    connection.stateUpdateHandler = nil
                    continuation.resume()
                case let .failed(error):
                    connection.stateUpdateHandler = nil
                    continuation.resume(throwing: error)
                default:
                    break
                }
            }
            connection.start(queue: queue)
        }
    }

    func send(_ text: String) {
        connection.send(content: Data(text.utf8), completion: .contentProcessed { _ in })
    }

    /// Reads until the server closes the connection, which it does after each response.
    func readToEnd() async -> String {
        let connection = connection
        var received = Data()
        while true {
            let (data, finished): (Data?, Bool) = await withCheckedContinuation { continuation in
                connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { data, _, isComplete, error in
                    continuation.resume(returning: (data, isComplete || error != nil))
                }
            }
            if let data { received.append(data) }
            if finished { break }
        }
        connection.cancel()
        return String(decoding: received, as: UTF8.self)
    }
}
