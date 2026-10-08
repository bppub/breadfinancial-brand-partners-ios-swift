//------------------------------------------------------------------------------
//  File:          PlacementUICoordinatorTests.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import BreadPartnersCore
import Foundation
import Testing
import UIKit

@testable import BreadPartners

@Suite
@MainActor
struct PlacementUICoordinatorTests {
    @Test(arguments: [
        PlacementTextRenderMode.linkedText,
        PlacementTextRenderMode.splitTextAndAction,
        PlacementTextRenderMode.swiftUILinkedText,
        PlacementTextRenderMode.swiftUISplitTextAndAction,
    ])
    func successForwardsTheSelectedRenderMode(renderMode: PlacementTextRenderMode) async {
        let renderer = PlacementTextRenderingSpy()
        let coordinator = makeCoordinator(textRenderer: renderer)
        let response = RTPSTestFixtures.Response.emptyPlacements
        let events = EventCapture()

        await coordinator.handle(
            .success(response),
            renderMode: renderMode,
            logger: Logger(),
            callback: events.record,
            onChallengeComplete: { _ in }
        )

        #expect(renderer.responseModels.count == 1)
        #expect(renderer.responseModels.first?.placements?.isEmpty == true)
        #expect(renderer.modes == [renderMode])
        #expect(events.eventCount == 0)
    }

    @Test
    func renderingFailureBecomesSDKError() async throws {
        let renderer = PlacementTextRenderingSpy(
            error: NSError(
                domain: "Renderer",
                code: 9,
                userInfo: [NSLocalizedDescriptionKey: "render failed"]
            )
        )
        let events = EventCapture()

        await makeCoordinator(textRenderer: renderer).handle(
            .success(RTPSTestFixtures.Response.emptyPlacements),
            renderMode: .linkedText,
            logger: Logger(),
            callback: events.record,
            onChallengeComplete: { _ in }
        )

        let error = try #require(sdkError(from: events))
        #expect(error.code == 500)
        #expect(error.localizedDescription == Constants.apiError(message: "render failed"))
    }

    @Test
    func challengeUsesFactoryAndForwardsCompletion() async {
        let challengeFactory = PlacementChallengeFactorySpy(controller: UIViewController())
        let coordinator = makeCoordinator(challengeFactory: challengeFactory)
        let events = EventCapture()
        var completedCookie: String?
        let logger = Logger()

        await coordinator.handle(
            .challenge(
                htmlContent: "<html>challenge</html>",
                originalURL: "https://challenge.test",
                error: NSError(domain: "Challenge", code: 0)
            ),
            renderMode: .linkedText,
            logger: logger,
            callback: events.record,
            onChallengeComplete: { completedCookie = $0 }
        )

        #expect(challengeFactory.htmlContent == "<html>challenge</html>")
        #expect(challengeFactory.originalURL == "https://challenge.test")
        #expect(challengeFactory.logger === logger)
        guard case let .renderPopupView(view) = events.first else {
            Issue.record("Expected challenge controller to be rendered")
            return
        }
        #expect(view === challengeFactory.controller)

        challengeFactory.onComplete?("retry-cookie")
        #expect(completedCookie == "retry-cookie")
    }

    @Test
    func failureOutcomeMapsToSDKError() async throws {
        let events = EventCapture()
        let failure = NSError(
            domain: "Placement",
            code: 42,
            userInfo: [NSLocalizedDescriptionKey: "request failed"]
        )

        await makeCoordinator().handle(
            .failure(failure),
            renderMode: .linkedText,
            logger: Logger(),
            callback: events.record,
            onChallengeComplete: { _ in }
        )

        let error = try #require(sdkError(from: events))
        #expect(error.code == 500)
        #expect(error.localizedDescription == Constants.apiError(message: "request failed"))
    }

    @Test
    func popupUsesFactoryAndPublishesOrderedEvents() {
        let popupFactory = PlacementPopupFactorySpy()
        let coordinator = makeCoordinator(popupFactory: popupFactory)
        let events = EventCapture()
        let merchantConfiguration = RTPSTestFixtures.MerchantConfigurationFixture.complete
        let placementsConfiguration = RTPSTestFixtures.PlacementConfigurationFixture.rtps
        let popupModel = RTPSTestFixtures.PopupPlacementModelFixture.embedded
        let logger = Logger()

        coordinator.presentPopup(
            popupModel,
            overlayType: .singleProductOverlay,
            merchantConfiguration: merchantConfiguration,
            placementsConfiguration: placementsConfiguration,
            integrationKey: "integration-key",
            logger: logger,
            callback: events.record
        )

        #expect(popupFactory.integrationKey == "integration-key")
        #expect(popupFactory.overlayType == .singleProductOverlay)
        #expect(popupFactory.logger === logger)
        let publishedEvents = events.events
        #expect(publishedEvents.count == 2)
        guard case .textClicked = publishedEvents[0] else {
            Issue.record("Expected textClicked to be published first")
            return
        }
        guard case let .renderPopupView(view) = publishedEvents[1] else {
            Issue.record("Expected popup controller to be published second")
            return
        }
        #expect(view === popupFactory.controller)
        #expect(view.modalPresentationStyle == .overCurrentContext)
        #expect(view.modalTransitionStyle == .crossDissolve)

        popupFactory.callback?(.popupClosed)
        #expect(events.eventCount == 3)
    }

    private func makeCoordinator(
        textRenderer: PlacementTextRenderingSpy = PlacementTextRenderingSpy(),
        challengeFactory: PlacementChallengeFactorySpy = PlacementChallengeFactorySpy(
            controller: UIViewController()
        ),
        popupFactory: PlacementPopupFactorySpy = PlacementPopupFactorySpy()
    ) -> PlacementUICoordinator {
        PlacementUICoordinator(
            textRenderer: textRenderer,
            challengeFactory: challengeFactory,
            popupFactory: popupFactory
        )
    }

    private func sdkError(from events: EventCapture) -> NSError? {
        guard case let .sdkError(error) = events.first else {
            Issue.record("Expected an SDK error event")
            return nil
        }
        return error as NSError
    }
}

@MainActor
private final class PlacementTextRenderingSpy: PlacementTextRendering {
    private(set) var modes: [PlacementTextRenderMode] = []
    private(set) var responseModels: [PlacementsResponse] = []
    private let error: Error?

    init(error: Error? = nil) {
        self.error = error
    }

    func renderTextPlacement(
        responseModel: PlacementsResponse,
        mode: PlacementTextRenderMode
    ) async throws {
        responseModels.append(responseModel)
        modes.append(mode)
        if let error {
            throw error
        }
    }
}

@MainActor
private final class PlacementChallengeFactorySpy: ChallengeControllerFactory, @unchecked Sendable {
    let controller: UIViewController
    private(set) var htmlContent: String?
    private(set) var originalURL: String?
    private(set) var logger: Logger?
    private(set) var onComplete: ((String) -> Void)?

    init(controller: UIViewController) {
        self.controller = controller
    }

    func makeChallengeController(
        htmlContent: String,
        originalURL: String,
        callback: @escaping (BreadPartnerEvents) -> Void,
        onComplete: @escaping (String) -> Void,
        logger: Logger
    ) -> UIViewController {
        self.htmlContent = htmlContent
        self.originalURL = originalURL
        self.logger = logger
        self.onComplete = onComplete
        return controller
    }
}

@MainActor
private final class PlacementPopupFactorySpy: PopupFactory, @unchecked Sendable {
    let controller = UIViewController()
    private(set) var integrationKey: String?
    private(set) var overlayType: PlacementOverlayType?
    private(set) var logger: Logger?
    private(set) var callback: ((BreadPartnerEvents) -> Void)?

    func makePopupController(
        integrationKey: String,
        merchantConfiguration: MerchantConfiguration,
        placementsConfiguration: PlacementConfiguration,
        popupPlacementModel: PopupPlacementModel,
        overlayType: PlacementOverlayType,
        logger: Logger,
        callback: @escaping (BreadPartnerEvents) -> Void
    ) -> UIViewController {
        self.integrationKey = integrationKey
        self.overlayType = overlayType
        self.logger = logger
        self.callback = callback
        return controller
    }
}
