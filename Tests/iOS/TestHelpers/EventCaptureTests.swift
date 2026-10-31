//------------------------------------------------------------------------------
//  File:          EventCaptureTests.swift
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
import Testing
@testable import BreadPartners

@Suite struct EventCaptureTests {
    @Test
    func recordsEventsInOrderAndReportsSDKErrors() {
        let capture = EventCapture()

        #expect(capture.events.isEmpty)
        #expect(capture.first == nil)
        #expect(capture.eventCount == 0)
        #expect(!capture.containsSDKError)
        #expect(capture.messages.isEmpty)

        capture.record(.textClicked)
        capture.record(.onSDKEventLog(logs: "one"))
        capture.record(.sdkError(error: NSError(domain: "SDK", code: 1)))

        #expect(capture.eventCount == 3)
        #expect(capture.events.count == 3)
        guard let first = capture.first else {
            Issue.record("Expected EventCapture to preserve the first event")
            return
        }
        if case .textClicked = first {
        } else {
            Issue.record("Expected EventCapture to preserve the first event")
        }
        #expect(capture.containsSDKError)
    }

    @Test
    func messagesReturnsOnlySDKLogMessagesInOrder() {
        let capture = EventCapture()

        capture.record(.textClicked)
        capture.record(.onSDKEventLog(logs: "first"))
        capture.record(.sdkError(error: NSError(domain: "SDK", code: 1)))
        capture.record(.onSDKEventLog(logs: "second"))

        #expect(capture.messages == ["first", "second"])
    }

    @Test
    func replacingEventsUpdatesCapturedState() {
        let capture = EventCapture()
        capture.events = [.onSDKEventLog(logs: "configured")]

        #expect(capture.eventCount == 1)
        #expect(capture.events.count == 1)
        #expect(capture.messages == ["configured"])
        #expect(capture.first != nil)
        #expect(!capture.containsSDKError)

        capture.record(.textClicked)

        #expect(capture.eventCount == 2)
    }

    @Test
    func waitForEventCountReturnsImmediatelyWhenAlreadyReached() async {
        let capture = EventCapture()
        capture.record(.textClicked)

        #expect(await capture.waitForEventCount(1, timeout: 0.1))
    }

    @Test
    func waitForEventCountObservesAnEventRecordedLater() async {
        let capture = EventCapture()
        let recordingTask = Task {
            try? await Task.sleep(nanoseconds: 20_000_000)
            capture.record(.textClicked)
        }

        #expect(await capture.waitForEventCount(1, timeout: 0.5))
        await recordingTask.value
        #expect(capture.eventCount == 1)
    }

    @Test
    func waitForEventCountReturnsFalseWhenTimeoutExpires() async {
        let capture = EventCapture()

        #expect(await !capture.waitForEventCount(1, timeout: 0.02))
        #expect(capture.eventCount == 0)
    }
}
