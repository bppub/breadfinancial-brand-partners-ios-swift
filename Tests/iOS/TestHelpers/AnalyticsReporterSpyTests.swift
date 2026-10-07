import Foundation
import Testing
import XCTest

@testable import BreadPartners

@Suite
struct AnalyticsReporterSpyTests {
    @Test
    func startsWithoutRecordedCalls() async {
        let reporter = AnalyticsReporterSpy()

        #expect(await reporter.calls.isEmpty)
    }

    @Test(arguments: [AnalyticsEvent.viewPlacement, .clickPlacement])
    func recordsEventAndUnchangedResponseWithoutAnExpectation(event: AnalyticsEvent) async throws {
        let reporter = AnalyticsReporterSpy()
        let response = makeResponse(id: "text", html: "<div>Offer</div>")

        await reporter.send(event: event, placementResponse: response)

        let calls = await reporter.calls
        #expect(calls.count == 1)
        let call = try #require(calls.first)
        #expect(call.event == event)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        #expect(try encoder.encode(call.placementResponse) == encoder.encode(response))
    }

    @Test
    func preservesCallOrderAndEachResponse() async throws {
        let reporter = AnalyticsReporterSpy()
        let textResponse = makeResponse(id: "text", html: "<div>Offer</div>")
        let popupResponse = makeResponse(id: "popup", html: "<iframe></iframe>")

        await reporter.send(event: .viewPlacement, placementResponse: textResponse)
        await reporter.send(event: .clickPlacement, placementResponse: popupResponse)

        let calls = await reporter.calls
        #expect(calls.map(\.event) == [.viewPlacement, .clickPlacement])
        #expect(calls.map { $0.placementResponse.placementContent?.first?.id } == ["text", "popup"])
        #expect(
            calls.map { $0.placementResponse.placementContent?.first?.contentData?.htmlContent }
                == ["<div>Offer</div>", "<iframe></iframe>"])
    }

    @Test
    func fulfillsExpectationForEachRecordedCallBeforeReturning() async throws {
        let reported = XCTestExpectation(description: "both analytics calls recorded")
        reported.expectedFulfillmentCount = 2
        let reporter = AnalyticsReporterSpy(reported: reported)
        let response = PlacementsResponse(placements: nil, placementContent: nil)

        await reporter.send(event: .viewPlacement, placementResponse: response)
        await reporter.send(event: .clickPlacement, placementResponse: response)

        try #require(await XCTWaiter.fulfillment(of: [reported], timeout: 0) == .completed)
        let calls = await reporter.calls
        #expect(calls.map(\.event) == [.viewPlacement, .clickPlacement])
        #expect(calls.allSatisfy { $0.placementResponse.placements == nil })
        #expect(calls.allSatisfy { $0.placementResponse.placementContent == nil })
    }

    private func makeResponse(id: String, html: String) -> PlacementsResponse {
        PlacementsResponse(
            placements: [
                PlacementsModel(
                    id: "placement", content: PlacementContentReferenceModel(contentId: id), renderContext: nil)
            ],
            placementContent: [
                PlacementContentModel(
                    id: id, contentType: "text", contentData: ContentDataModel(htmlContent: html),
                    metadata: MetadataModel(
                        placementId: "placement", productType: "CC", messageId: "message", templateId: "template")
                )
            ]
        )
    }
}
