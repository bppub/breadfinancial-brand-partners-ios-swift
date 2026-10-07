//------------------------------------------------------------------------------
//  File:          LogCaptureTests.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

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
