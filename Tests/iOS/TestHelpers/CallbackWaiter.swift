//------------------------------------------------------------------------------
//  File:          CallbackWaiter.swift
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

/// Waits for an asynchronous callback while keeping the test bounded.
///
/// Use this instead of Swift Testing's `.timeLimit` trait for tests that support iOS 15, where
/// that trait is unavailable. A missing callback then returns a value the test can assert on,
/// rather than leaving the test suspended indefinitely.
///
/// - Parameters:
///   - timeout: The maximum number of seconds to wait before treating the callback as missing.
///   - register: Starts the operation and installs its callback. Yield and finish the supplied
///     continuation when that callback arrives.
/// - Returns: `true` if the callback arrives before the timeout; otherwise, `false`.
@MainActor
func waitForCallback(
    timeout: TimeInterval = 300,
    register: (AsyncStream<Void>.Continuation) -> Void
) async -> Bool {
    let (stream, signal) = AsyncStream<Void>.makeStream()

    register(signal)

    return await withTaskGroup(of: Bool.self) { group in
        group.addTask {
            for await _ in stream {
                return true
            }
            return false
        }

        group.addTask {
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            return false
        }

        let didReceiveCallback = await group.next() ?? false

        // Stop the losing wait after either the callback or timeout wins.
        group.cancelAll()

        return didReceiveCallback
    }
}
