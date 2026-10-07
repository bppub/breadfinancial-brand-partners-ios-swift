import BreadPartnersTestSupport
import Foundation
import Testing
import UIKit
import XCTest

@testable import BreadPartners

@Suite
@MainActor
struct HTMLContentRendererTests {
    private let textHTML = """
        <div class="ep-text-placement" data-action-type="SHOW_OVERLAY" data-action-content-id="popup">
            <div class="epjs-body">Offer <span class="epjs-body-action"><a>Apply</a></span></div>
        </div>
        """
    private let popupHTML = """
        <div data-overlay-metadata data-overlay-type="EMBEDDED_OVERLAY"></div>
        <iframe src="about:blank"></iframe>
        """

    @Test
    func missingTextContentDoesNotReportAnalyticsAndPreservesErrorCallback() async throws {
        let httpClient = HTTPClientSpy()
        let reporterFactory = makeReporterFactory()
        let events = EventCapture()
        let renderer = HTMLContentRenderer(
            integrationKey: "brand", merchantConfiguration: MerchantConfiguration(),
            placementsConfiguration: PlacementConfiguration(), logger: Logger(),
            analyticsReporter: reporterFactory.makeReporter(httpClient: httpClient),
            callback: events.record
        )

        await renderer.handleTextPlacement(responseModel: PlacementsResponse(placements: nil, placementContent: nil))

        #expect(await httpClient.requestCount == 0)
        #expect(events.eventCount == 1)
        guard case let .sdkError(error) = try #require(events.first) else {
            Issue.record("Expected the existing missing text content error")
            return
        }
        #expect((error as NSError).code == 500)
        #expect(error.localizedDescription == Constants.noTextPlacementError)
    }

    @Test(arguments: [false, true], [false, true])
    func successfulTextReportsOneViewAndPreservesRenderCallback(splitTextAndAction: Bool, forSwiftUI: Bool) async throws
    {
        let httpClient = HTTPClientSpy(outcomes: [.success(Data())])
        let reported = XCTestExpectation(description: "view reported")
        let reporterFactory = makeReporterFactory()
        let events = EventCapture()
        let renderer = makeRenderer(
            reporterFactory: reporterFactory, httpClient: httpClient, reported: reported, events: events,
            splitTextAndAction: splitTextAndAction, forSwiftUI: forSwiftUI
        )
        let response = makeResponse(textHTML: textHTML)

        await renderer.handleTextPlacement(responseModel: response)

        #expect(events.eventCount == 1)
        switch (splitTextAndAction, forSwiftUI, try #require(events.first)) {
        case (false, false, .renderTextViewWithLink): break
        case (false, true, .renderSwiftUITextViewWithLink): break
        case (true, false, .renderSeparateTextAndButton): break
        case (true, true, .renderSwiftUISeparateTextAndButton): break
        default: Issue.record("Expected the existing render callback for the selected mode")
        }
        #expect(await XCTWaiter.fulfillment(of: [reported], timeout: 2) == .completed)
        let requests = await httpClient.requests
        #expect(requests.count == 1)
        #expect(requests.first?.method == .OPTIONS)
        let payload = try JSONDecoder().decode(Analytics.Payload.self, from: #require(requests.first?.body))
        #expect(payload.name == "view-placement")
        #expect(payload.props?.eventProperties?.placementContent?.id == "text")
        #expect(events.eventCount == 1)
    }

    @Test
    func validPopupReportsOneClickAndPreservesOrderedCallbacks() async throws {
        let httpClient = HTTPClientSpy(outcomes: [.success(Data())])
        let reported = XCTestExpectation(description: "click reported")
        let reporterFactory = makeReporterFactory()
        let events = EventCapture()
        let renderer = makeRenderer(
            reporterFactory: reporterFactory, httpClient: httpClient, reported: reported, events: events)
        let response = makeResponse(textHTML: textHTML, popupHTML: popupHTML)
        let model = try #require(try await HTMLContentParser().extractTextPlacementModel(htmlContent: textHTML))

        await renderer.handlePopupPlacement(responseModel: response, textPlacementModel: model)

        #expect(events.eventCount == 2)
        guard case .textClicked = events.events[0],
            case let .renderPopupView(view) = events.events[1]
        else {
            Issue.record("Expected textClicked followed by renderPopupView")
            return
        }
        let popup = try #require(view as? PopupController)
        #expect(popup.overlayType == .embeddedOverlay)
        #expect(popup.integrationKey == "brand")
        #expect(popup.modalPresentationStyle == .overCurrentContext)
        #expect(popup.modalTransitionStyle == .crossDissolve)
        #expect(await XCTWaiter.fulfillment(of: [reported], timeout: 2) == .completed)
        let requests = await httpClient.requests
        #expect(requests.count == 1)
        #expect(requests.first?.method == .OPTIONS)
        let payload = try JSONDecoder().decode(Analytics.Payload.self, from: #require(requests.first?.body))
        #expect(payload.name == "click-placement")
        #expect(payload.props?.eventProperties?.placementContent?.id == "text")
        popup.callback(.popupClosed)
        guard case .popupClosed = try #require(events.events.last) else {
            Issue.record("Expected the popup callback to be forwarded unchanged")
            return
        }
    }

    @Test(arguments: [nil, "", "<div data-overlay-metadata data-overlay-type='UNKNOWN'></div>"] as [String?])
    func popupParsingOrOverlayFailureDoesNotReportAndPreservesError(popupHTML: String?) async throws {
        let httpClient = HTTPClientSpy()
        let reporterFactory = makeReporterFactory()
        let events = EventCapture()
        let renderer = makeRenderer(reporterFactory: reporterFactory, httpClient: httpClient, events: events)
        let model = try #require(try await HTMLContentParser().extractTextPlacementModel(htmlContent: textHTML))

        await renderer.handlePopupPlacement(
            responseModel: makeResponse(textHTML: textHTML, popupHTML: popupHTML), textPlacementModel: model
        )

        #expect(await httpClient.requestCount == 0)
        #expect(events.eventCount == 1)
        guard case let .sdkError(error) = try #require(events.first) else {
            Issue.record("Expected the existing popup parsing or overlay error")
            return
        }
        #expect((error as NSError).code == 500)
        #expect(
            error.localizedDescription
                == (popupHTML == nil ? Constants.popupPlacementParsingError : Constants.missingPopupPlacementError))
    }

    @Test
    func noActionTapPreservesTextClickedWithoutClickAnalytics() async throws {
        let httpClient = HTTPClientSpy(outcomes: [.success(Data())])
        let reported = XCTestExpectation(description: "view reported")
        let reporterFactory = makeReporterFactory()
        let events = EventCapture()
        let renderer = makeRenderer(
            reporterFactory: reporterFactory, httpClient: httpClient, reported: reported, events: events,
            splitTextAndAction: true
        )
        let html = textHTML.replacingOccurrences(of: "SHOW_OVERLAY", with: "NO_ACTION")

        await renderer.handleTextPlacement(responseModel: makeResponse(textHTML: html))
        await renderer.handleLinkInteraction(link: "Apply")

        #expect(events.eventCount == 2)
        guard case .renderSeparateTextAndButton = events.events[0], case .textClicked = events.events[1] else {
            Issue.record("Expected the render callback followed by textClicked")
            return
        }
        #expect(await XCTWaiter.fulfillment(of: [reported], timeout: 2) == .completed)
        let requests = await httpClient.requests
        #expect(requests.count == 1)
        let payload = try JSONDecoder().decode(Analytics.Payload.self, from: #require(requests.first?.body))
        #expect(payload.name == "view-placement")
    }

    @Test
    func incompleteTextHTMLRetainsCurrentSuccessfulParseAndViewReporting() async throws {
        let httpClient = HTTPClientSpy(outcomes: [.success(Data())])
        let reported = XCTestExpectation(description: "view reported")
        let reporterFactory = makeReporterFactory()
        let events = EventCapture()
        let renderer = makeRenderer(
            reporterFactory: reporterFactory, httpClient: httpClient, reported: reported, events: events)

        await renderer.handleTextPlacement(responseModel: makeResponse(textHTML: ""))

        #expect(await XCTWaiter.fulfillment(of: [reported], timeout: 2) == .completed)
        let requests = await httpClient.requests
        #expect(requests.count == 1)
        let payload = try JSONDecoder().decode(Analytics.Payload.self, from: #require(requests.first?.body))
        #expect(payload.name == "view-placement")
        #expect(events.eventCount == 1)
        guard case .renderTextViewWithLink = try #require(events.first) else {
            Issue.record("Expected the current empty text render callback")
            return
        }
    }

    private func makeReporterFactory() -> LiveAnalyticsReporterFactory {
        LiveAnalyticsReporterFactory(
            endpointProvider: LiveAPIEndpointProvider(environment: .stage)
        )
    }

    private func makeRenderer(
        reporterFactory: any AnalyticsReporterFactory,
        httpClient: HTTPClientSpy,
        reported: XCTestExpectation? = nil,
        events: EventCapture,
        splitTextAndAction: Bool = false,
        forSwiftUI: Bool = false
    ) -> HTMLContentRenderer {
        let client: any HTTPClient
        if let reported {
            client = AnalyticsHTTPClientObserver(client: httpClient, reported: reported)
        } else {
            client = httpClient
        }
        return HTMLContentRenderer(
            integrationKey: "brand", merchantConfiguration: MerchantConfiguration(),
            placementsConfiguration: PlacementConfiguration().withDefaultPopupStylingIfMissing(),
            splitTextAndAction: splitTextAndAction, forSwiftUI: forSwiftUI,
            logger: Logger(),
            analyticsReporter: reporterFactory.makeReporter(httpClient: client),
            callback: events.record
        )
    }

    private func makeResponse(textHTML: String, popupHTML: String? = nil) -> PlacementsResponse {
        var content = [
            PlacementContentModel(
                id: "text", contentType: "text", contentData: ContentDataModel(htmlContent: textHTML), metadata: nil
            )
        ]
        if let popupHTML {
            content.append(
                PlacementContentModel(
                    id: "popup", contentType: "overlay", contentData: ContentDataModel(htmlContent: popupHTML),
                    metadata: nil
                ))
        }
        return PlacementsResponse(placements: nil, placementContent: content)
    }
}
