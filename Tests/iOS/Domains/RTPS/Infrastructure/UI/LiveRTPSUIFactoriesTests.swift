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
        let merchantConfiguration = RTPSTestFixtures.MerchantConfigurationFixture.complete
        let placementsConfiguration = RTPSTestFixtures.PlacementConfigurationFixture.rtps
        let popupPlacementModel = RTPSTestFixtures.PopupPlacementModelFixture.embedded
        let logger = Logger()
        let events = EventCapture()

        let viewController = LivePopupFactory().makePopupController(
            integrationKey: "integration-key",
            merchantConfiguration: merchantConfiguration,
            placementsConfiguration: placementsConfiguration,
            popupPlacementModel: popupPlacementModel,
            logger: logger,
            callback: events.record
        )

        let controller = try #require(viewController as? PopupController)
        #expect(controller.integrationKey == "integration-key")
        #expect(controller.merchantConfiguration?.storeNumber == merchantConfiguration.storeNumber)
        #expect(controller.placementsConfiguration?.rtpsData != nil)
        #expect(controller.popupModel.overlayType == popupPlacementModel.overlayType)
        #expect(controller.popupModel.location == popupPlacementModel.location)
        #expect(controller.popupModel.webViewUrl == popupPlacementModel.webViewUrl)
        #expect(controller.overlayType == .embeddedOverlay)
        #expect(controller.logger === logger)

        controller.callback(.textClicked)
        guard case .textClicked = events.first else {
            Issue.record("Expected the popup callback to be retained")
            return
        }
    }

}
