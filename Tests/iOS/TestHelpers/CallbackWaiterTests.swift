//------------------------------------------------------------------------------
//  File:          CallbackWaiterTests.swift
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

@MainActor
@Suite
struct CallbackWaiterTests {
    @Test
    func returnsTrueWhenRegisteredCallbackSignals() async {
        let didReceiveCallback = await waitForCallback(timeout: 1) { signal in
            signal.yield(())
            signal.finish()
        }

        #expect(didReceiveCallback)
    }

    @Test
    func returnsFalseWhenCallbackDoesNotArriveBeforeTimeout() async {
        var pendingCallback: AsyncStream<Void>.Continuation?

        let didReceiveCallback = await waitForCallback(timeout: 0.05) { signal in
            pendingCallback = signal
        }
        pendingCallback?.finish()

        #expect(!didReceiveCallback)
    }
}
