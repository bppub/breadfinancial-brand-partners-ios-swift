//------------------------------------------------------------------------------
//  File:          EventCapture.swift
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
@testable import BreadPartners

final class EventCapture: @unchecked Sendable {
    private let lock = NSLock()
    private var recordedEvents: [BreadPartnerEvents] = []

    var events: [BreadPartnerEvents] {
        get {
            lock.lock()
            defer { lock.unlock() }
            return recordedEvents
        }
        set {
            lock.lock()
            recordedEvents = newValue
            lock.unlock()
        }
    }

    var first: BreadPartnerEvents? {
        lock.lock()
        defer { lock.unlock() }
        return recordedEvents.first
    }

    var containsSDKError: Bool {
        lock.lock()
        defer { lock.unlock() }
        return recordedEvents.contains { event in
            if case .sdkError = event { return true }
            return false
        }
    }

    var eventCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return recordedEvents.count
    }

    var messages: [String] {
        lock.lock()
        defer { lock.unlock() }
        return recordedEvents.compactMap { event in
            guard case let .onSDKEventLog(logs) = event else { return nil }
            return logs
        }
    }

    func record(_ event: BreadPartnerEvents) {
        lock.lock()
        recordedEvents.append(event)
        lock.unlock()
    }
}
