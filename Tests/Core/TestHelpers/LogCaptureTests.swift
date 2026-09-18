import Testing

@Suite struct LogCaptureTests {
    @Test
    func startsWithNoRecordedMessages() {
        let log = LogCapture()

        #expect(log.recordedMessages.isEmpty)
    }

    @Test
    func recordsEachMessage() {
        let log = LogCapture()

        log.record("first message")
        log.record("second message")

        #expect(log.recordedMessages == ["first message", "second message"])
    }

    @Test
    func preservesRecordingOrder() {
        let log = LogCapture()
        let messages = ["first", "second", "third"]

        for message in messages {
            log.record(message)
        }

        #expect(log.recordedMessages == messages)
    }
}
