//------------------------------------------------------------------------------
//  File:          RTPSUICoordinatorTests.swift
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
import UIKit

@testable import BreadPartners

@Suite
@MainActor
struct RTPSUICoordinatorTests {
    @Test
    func liveUsesLiveFactories() {
        let coordinator = RTPSUICoordinator.live
        let dependencies = Mirror(reflecting: coordinator).children.map(\.value)

        #expect(dependencies.contains { $0 is LiveChallengeControllerFactory })
        #expect(dependencies.contains { $0 is LivePopupFactory })
    }

    @Test
    func presentChallengeUsesFactoryAndPublishesController() {
        let controller = UIViewController()
        let factory = ChallengeControllerFactorySpy(controller: controller)
        let coordinator = RTPSUICoordinator(
            challengeFactory: factory,
            popupFactory: PopupFactorySpy()
        )
        let events = EventCapture()
        let logger = Logger()
        var completionValue: String?

        coordinator.presentChallenge(
            htmlContent: "challenge",
            originalURL: "https://challenge.test",
            callback: events.record,
            logger: logger,
            onComplete: { completionValue = $0 }
        )

        #expect(factory.htmlContent == "challenge")
        #expect(factory.originalURL == "https://challenge.test")
        #expect(factory.logger === logger)
        guard case let .renderPopupView(view) = events.first else {
            Issue.record("Expected a render popup event")
            return
        }
        #expect(view === controller)

        factory.callback?(.popupClosed)
        factory.onComplete?("challenge-result")
        #expect(events.eventCount == 2)
        #expect(completionValue == "challenge-result")
    }

    @Test
    func presentFailureMapsMissingRequiredFields() throws {
        let events = EventCapture()

        makeCoordinator().presentFailure(.missingRequiredFields, callback: events.record)

        let error = try #require(sdkError(from: events))
        #expect(error.code == 400)
        #expect(error.localizedDescription == Constants.prescreenRequiredFieldsError)
    }

    @Test
    func presentFailureMapsAPIMessage() throws {
        let events = EventCapture()

        makeCoordinator().presentFailure(.api(message: "network failure"), callback: events.record)

        let error = try #require(sdkError(from: events))
        #expect(error.code == 500)
        #expect(error.localizedDescription == Constants.apiError(message: "network failure"))
    }

    @Test
    func presentFailurePublishesUnderlyingError() throws {
        let events = EventCapture()
        let underlyingError = NSError(domain: "Test", code: 7)

        makeCoordinator().presentFailure(.underlying(underlyingError), callback: events.record)

        let error = try #require(sdkError(from: events))
        #expect(error === underlyingError)
    }

    @Test
    func presentPlacementUsesFactoryAndPublishesEventsInOrder() {
        let popupFactory = PopupFactorySpy()
        let coordinator = makeCoordinator(popupFactory: popupFactory)
        let events = EventCapture()
        let logger = Logger()
        let popupInput = PopupInput.embedded(
            style: PopUpStyling(),
            logoURL: "https://logo.test",
            webViewURL: "https://embedded.test",
            showsCloseButton: false
        )

        coordinator.presentPlacement(
            popupInput,
            logger: logger,
            callback: events.record
        )

        guard case let .embedded(content) = popupFactory.input?.content else {
            Issue.record("Expected the popup factory to receive embedded content")
            return
        }
        #expect(content.logoURL == "https://logo.test")
        #expect(content.webViewURL == "https://embedded.test")
        #expect(content.showsCloseButton == false)
        #expect(popupFactory.logger === logger)

        let publishedEvents = events.events
        #expect(publishedEvents.count == 2)
        guard case .textClicked = publishedEvents[0] else {
            Issue.record("Expected textClicked to be published first")
            return
        }
        guard case let .renderPopupView(view) = publishedEvents[1] else {
            Issue.record("Expected the popup controller to be published second")
            return
        }
        #expect(view === popupFactory.controller)

        popupFactory.callback?(.popupClosed)
        #expect(events.eventCount == 3)
    }

    private func makeCoordinator(
        popupFactory: PopupFactorySpy = PopupFactorySpy()
    ) -> RTPSUICoordinator {
        RTPSUICoordinator(
            challengeFactory: ChallengeControllerFactorySpy(controller: UIViewController()),
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
private final class ChallengeControllerFactorySpy: ChallengeControllerFactory, @unchecked Sendable {
    let controller: UIViewController
    private(set) var htmlContent: String?
    private(set) var originalURL: String?
    private(set) var logger: Logger?
    private(set) var callback: ((BreadPartnerEvents) -> Void)?
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
        self.callback = callback
        self.onComplete = onComplete
        return controller
    }
}

@MainActor
private final class PopupFactorySpy: PopupFactory, @unchecked Sendable {
    let controller = UIViewController()
    private(set) var input: PopupInput?
    private(set) var logger: Logger?
    private(set) var callback: ((BreadPartnerEvents) -> Void)?

    func makePopupController(
        input: PopupInput,
        logger: Logger,
        callback: @escaping (BreadPartnerEvents) -> Void
    ) -> UIViewController {
        self.input = input
        self.logger = logger
        self.callback = callback
        return controller
    }
}
