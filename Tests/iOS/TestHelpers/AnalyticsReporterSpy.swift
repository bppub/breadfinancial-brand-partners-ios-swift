//------------------------------------------------------------------------------
//  File:          AnalyticsReporterSpy.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

@testable import BreadPartners

actor AnalyticsReporterSpy: AnalyticsReporting {
    struct Call: Sendable {
        let event: AnalyticsEvent
        let placementResponse: PlacementsResponse
    }

    private(set) var calls: [Call] = []
    private var waiters: [(count: Int, continuation: CheckedContinuation<[Call], Never>)] = []

    func send(event: AnalyticsEvent, placementResponse: PlacementsResponse) async {
        calls.append(Call(event: event, placementResponse: placementResponse))
        let ready = waiters.filter { calls.count >= $0.count }
        waiters.removeAll { calls.count >= $0.count }
        ready.forEach { $0.continuation.resume(returning: calls) }
    }

    /// Suspends until at least `count` calls are recorded; no wall-clock timeout so slow CI cannot flake.
    func calls(atLeast count: Int) async -> [Call] {
        if calls.count >= count { return calls }
        return await withCheckedContinuation { waiters.append((count, $0)) }
    }
}
