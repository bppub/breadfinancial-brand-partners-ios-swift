//------------------------------------------------------------------------------
//  File:          LogCapture.swift
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

final class LogCapture: @unchecked Sendable {
    private let lock = NSLock()
    private var messages: [String] = []

    var recordedMessages: [String] {
        lock.lock()
        defer { lock.unlock() }
        return messages
    }

    func record(_ message: String) {
        lock.lock()
        messages.append(message)
        lock.unlock()
    }
}
