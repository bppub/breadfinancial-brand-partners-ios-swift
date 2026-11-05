//------------------------------------------------------------------------------
//  File:          LiveRTPSUIFactoriesTests.swift
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

@testable import BreadPartners

@Suite
@MainActor
struct LiveRTPSUIFactoriesTests {
    @Test
    func challengeFactoryMakesChallengeController() {
        let controller = LiveChallengeControllerFactory().makeChallengeController(
            htmlContent: "<html>challenge</html>",
            originalURL: "https://challenge.test",
            callback: { _ in },
            onComplete: { _ in },
            logger: Logger()
        )

        #expect(controller is ChallengeController)
        controller.loadViewIfNeeded()
    }

    @Test
    func popupFactoryConfiguresEmbeddedPopupController() throws {
        let model = RTPSTestFixtures.PopupPlacementModelFixture.embedded
        let popupInput = PopupInput.embedded(
            style: PopUpStyling(),
            logoURL: model.brandLogoUrl,
            webViewURL: model.webViewUrl,
            showsCloseButton: model.location != "RTPS-Approval"
        )
        let logger = Logger()
        let events = EventCapture()

        let viewController = LivePopupFactory().makePopupController(
            input: popupInput,
            logger: logger,
            callback: events.record
        )

        let controller = try #require(viewController as? PopupController)
        guard case let .embedded(content) = controller.input.content else {
            Issue.record("Expected an embedded popup input")
            return
        }
        #expect(content.logoURL == RTPSTestFixtures.PopupPlacementModelFixture.embedded.brandLogoUrl)
        #expect(content.webViewURL == RTPSTestFixtures.PopupPlacementModelFixture.embedded.webViewUrl)
        #expect(controller.logger === logger)

        controller.callback(.textClicked)
        guard case .textClicked = events.first else {
            Issue.record("Expected the popup callback to be retained")
            return
        }
    }

}
