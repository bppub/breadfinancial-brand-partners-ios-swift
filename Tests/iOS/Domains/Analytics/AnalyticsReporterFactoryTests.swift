//------------------------------------------------------------------------------
//  File:          AnalyticsReporterFactoryTests.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import BreadPartnersTestSupport
import Foundation
import Testing

@testable import BreadPartners

@Suite
struct AnalyticsReporterFactoryTests {
    private let endpoints = LiveAPIEndpointProvider(environment: .stage)
    private let response = PlacementsResponse(placements: nil, placementContent: nil)

    private var factory: LiveAnalyticsReporterFactory {
        LiveAnalyticsReporterFactory(endpointProvider: endpoints)
    }

    @Test
    func createsLiveAnalyticsReporter() {
        let reporter = factory.makeReporter(httpClient: HTTPClientSpy())

        #expect(reporter is LiveAnalyticsReporter)
    }

    @Test
    func reportersUseTheirOwnHTTPClients() async {
        let factory = factory
        let viewClient = HTTPClientSpy(outcomes: [.success(Data())])
        let clickClient = HTTPClientSpy(outcomes: [.success(Data())])
        let viewReporter = factory.makeReporter(httpClient: viewClient)
        let clickReporter = factory.makeReporter(httpClient: clickClient)

        await viewReporter.send(event: .viewPlacement, placementResponse: response)

        #expect(await viewClient.requestCount == 1)
        #expect(await clickClient.requestCount == 0)

        await clickReporter.send(event: .clickPlacement, placementResponse: response)

        #expect(await viewClient.requestCount == 1)
        #expect(await clickClient.requestCount == 1)
    }

    @Test
    func failedReportDoesNotPreventAnotherReporterFromSending() async throws {
        let factory = factory
        let failingClient = HTTPClientSpy(outcomes: [.failure(NSError(domain: "analytics-test", code: 500))])
        let succeedingClient = HTTPClientSpy(outcomes: [.success(Data())])
        let failingReporter = factory.makeReporter(httpClient: failingClient)
        let succeedingReporter = factory.makeReporter(httpClient: succeedingClient)

        await failingReporter.send(event: .viewPlacement, placementResponse: response)
        await succeedingReporter.send(event: .clickPlacement, placementResponse: response)

        #expect(await failingClient.requestCount == 1)
        #expect(await succeedingClient.requestCount == 1)
        let payload = try await payload(from: succeedingClient)
        #expect(payload.name == "click-placement")
    }

    @Test(arguments: [AnalyticsEvent.viewPlacement, .clickPlacement])
    func sendsExpectedEventNameToInjectedEndpoint(event: AnalyticsEvent) async throws {
        let client = HTTPClientSpy(outcomes: [.success(Data())])
        let reporter = factory.makeReporter(httpClient: client)

        await reporter.send(event: event, placementResponse: response)

        let requests = await client.requests
        #expect(requests.count == 1)
        let expectedEndpoint: APIEndpoint = event == .viewPlacement ? .viewPlacement : .clickPlacement
        #expect(requests.first?.url == endpoints.url(for: expectedEndpoint))
        let payload = try await payload(from: client)
        #expect(payload.name == (event == .viewPlacement ? "view-placement" : "click-placement"))
    }

    @Test(arguments: [AnalyticsEvent.viewPlacement, .clickPlacement])
    func preservesTimestampDeviceContextAndPlaceholderValues(event: AnalyticsEvent) async throws {
        let client = HTTPClientSpy(outcomes: [.success(Data())])
        let reporter = factory.makeReporter(httpClient: client)
        let expectedUserAgent = await DeviceInformationProvider.userAgent
        let earliestTimestamp = formattedUTCTimestamp(for: Date())

        await reporter.send(event: event, placementResponse: response)

        let latestTimestamp = formattedUTCTimestamp(for: Date())
        let payload = try await payload(from: client)
        let timestamp = try #require(payload.context?.timestamp)
        #expect(timestamp >= earliestTimestamp)
        #expect(timestamp <= latestTimestamp)
        #expect(payload.context?.browserCtx?.userAgent == expectedUserAgent)
        #expect(payload.context?.apiKey == "")
        #expect(payload.context?.trackingInfo?.sessionTrackingId == "ToDO")
    }

    private func payload(from client: HTTPClientSpy) async throws -> Analytics.Payload {
        let requests = await client.requests
        return try JSONDecoder().decode(Analytics.Payload.self, from: #require(requests.first?.body))
    }
}
