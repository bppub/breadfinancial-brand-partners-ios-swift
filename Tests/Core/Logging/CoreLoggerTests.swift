import Foundation
import Testing
@testable import BreadPartnersCore

@Suite struct CoreLoggerTests {
    private final class MessageBox: @unchecked Sendable {
        var messages: [String] = []
    }

    private struct NonDisplayableHeaderValue {}

    @Test
    func disabledLoggerDoesNotEmit() {
        let box = MessageBox()
        let logger = CoreLogger { box.messages.append($0) }

        logger.emit(["hidden"])

        #expect(box.messages.isEmpty)
    }

    @Test
    func enabledLoggerJoinsItemsAndEmitsOnce() {
        let box = MessageBox()
        let logger = CoreLogger { box.messages.append($0) }
        logger.isEnabled = true

        logger.emit(["value", 42], separator: " | ")

        #expect(box.messages == ["value | 42"])
    }

    @Test
    func defaultSinkAcceptsEmittedMessage() {
        let logger = CoreLogger()
        logger.isEnabled = true

        logger.emit(["default sink"])
    }

    @Test
    func requestMessageSortsHeadersAndFormatsJSONBody() throws {
        let logger = CoreLogger()
        let url = try #require(URL(string: "https://example.com/request"))
        let message = logger.requestMessage(
            url: url,
            method: "POST",
            headers: ["Z-Header": "last", "A-Header": "first"],
            body: Data(#"{"value":1}"#.utf8)
        )
        let firstHeader = try #require(message.range(of: "A-Header"))
        let lastHeader = try #require(message.range(of: "Z-Header"))

        #expect(message.contains("URL     : https://example.com/request"))
        #expect(message.contains("Method  : POST"))
        #expect(firstHeader.lowerBound < lastHeader.lowerBound)
        #expect(message.contains("\"value\" : 1"))
    }

    @Test
    func requestMessageReportsMissingHeadersAndBody() throws {
        let logger = CoreLogger()
        let url = try #require(URL(string: "https://example.com/request"))
        let message = logger.requestMessage(
            url: url,
            method: "GET",
            headers: nil,
            body: nil
        )

        #expect(message.contains("Headers : None"))
        #expect(message.contains("Body    : No Body"))
    }

    @Test
    func requestMessageTreatsPlainTextAsMissingBody() throws {
        let logger = CoreLogger()
        let url = try #require(URL(string: "https://example.com/request"))
        let message = logger.requestMessage(
            url: url,
            method: "POST",
            headers: nil,
            body: Data("plain text".utf8)
        )

        #expect(message.contains("Body    : No Body"))
    }

    @Test
    func responseMessageUsesPlainTextBody() throws {
        let logger = CoreLogger()
        let url = try #require(URL(string: "https://example.com/response"))
        let message = logger.responseMessage(
            url: url,
            statusCode: 503,
            headers: [:],
            body: Data("unavailable".utf8)
        )

        #expect(message.contains("Status Code : 503"))
        #expect(message.contains("Body        : unavailable"))
    }

    @Test
    func responseMessageSortsHeadersAndRejectsNonDisplayableValues() throws {
        let logger = CoreLogger()
        let url = try #require(URL(string: "https://example.com/response"))
        let headers: [AnyHashable: Any] = [
            "Z-Header": "last",
            "A-Header": "first",
            "Hidden-Value": NonDisplayableHeaderValue(),
        ]
        let message = logger.responseMessage(
            url: url,
            statusCode: 200,
            headers: headers,
            body: nil
        )
        let firstHeader = try #require(message.range(of: "A-Header: first"))
        let lastHeader = try #require(message.range(of: "Z-Header: last"))

        #expect(firstHeader.lowerBound < lastHeader.lowerBound)
        #expect(!message.contains("Hidden-Value"))
    }

    @Test
    func responseMessageFormatsJSONBody() throws {
        let logger = CoreLogger()
        let url = try #require(URL(string: "https://example.com/response"))
        let message = logger.responseMessage(
            url: url,
            statusCode: 200,
            headers: [:],
            body: Data(#"{"status":"ok"}"#.utf8)
        )

        #expect(message.contains("\"status\" : \"ok\""))
    }

    @Test
    func responseMessageRejectsInvalidUTF8Body() throws {
        let logger = CoreLogger()
        let url = try #require(URL(string: "https://example.com/response"))
        let message = logger.responseMessage(
            url: url,
            statusCode: 200,
            headers: [:],
            body: Data([0xFF])
        )

        #expect(message.contains("Body        : No Body"))
    }

    @Test
    func specializedMessagesContainTheirPayloads() throws {
        let logger = CoreLogger()
        let url = try #require(URL(string: "https://example.com/page"))

        #expect(logger.loadingURLMessage(url).contains(url.absoluteString))
        #expect(logger.reCaptchaTokenMessage("token-123").contains("token-123"))
        #expect(
            logger.applicationResultMessage(["applicationId": "app-1"])
                .contains("Application ID     : app-1")
        )
        #expect(
            logger.applicationResultMessage([:])
                .contains("Application ID     : N/A")
        )
        #expect(logger.webAnchorsMessage("anchor-data").contains("anchor-data"))
    }
}
