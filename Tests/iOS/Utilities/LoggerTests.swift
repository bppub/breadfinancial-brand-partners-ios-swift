import Foundation
import Testing
@testable import BreadPartners

@Suite struct LoggerTests {
    private final class EventBox: @unchecked Sendable {
        var events: [BreadPartnerEvents] = []
    }

    @Test
    func disabledLoggerDoesNotEmitEvent() {
        let box = EventBox()
        let logger = Logger()
        logger.setCallback { box.events.append($0) }

        logger.debugPrint("hidden")

        #expect(box.events.isEmpty)
    }

    @Test
    func enabledLoggerEmitsJoinedMessage() {
        let box = EventBox()
        let logger = Logger()
        logger.setLogging(enabled: true)
        logger.setCallback { box.events.append($0) }

        logger.debugPrint("value", 42, separator: " | ")

        #expect(box.events.count == 1)
        guard case let .onSDKEventLog(logs)? = box.events.first else {
            Issue.record("Expected an SDK log event")
            return
        }
        #expect(logs == "value | 42")
    }

    @Test
    func requestLoggingEmitsOneFormattedEvent() throws {
        let box = EventBox()
        let logger = Logger()
        logger.setLogging(enabled: true)
        logger.setCallback { box.events.append($0) }
        let url = try #require(URL(string: "https://example.com/request"))

        logger.logRequestDetails(
            url: url,
            method: "POST",
            headers: ["X-Test": "value"],
            body: Data(#"{"id":1}"#.utf8)
        )

        #expect(box.events.count == 1)
        guard case let .onSDKEventLog(logs)? = box.events.first else {
            Issue.record("Expected an SDK log event")
            return
        }
        #expect(logs.contains("Request Details"))
        #expect(logs.contains("X-Test: value"))
        #expect(logs.contains("\"id\" : 1"))
    }
}
