//------------------------------------------------------------------------------
//  File:          PopupUIExtensionTests.swift
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
struct PopupUIExtensionTests {
    @Test
    func loadsPopupModelUsingCTAID() async {
        let fetcher = PopupModelFetcherSpy(model: makePopupModel(title: "Fetched popup"))
        let controller = makeController(
            onLoadFollowUpPopupModel: { id in await fetcher.fetch(id) },
            callback: { _ in }
        )

        await controller.loadFollowUpPopupModel()

        #expect(await fetcher.requestedIDs == ["follow-up-fetch"])
        #expect(controller.webViewPlacementModel?.overlayTitle.string == "Fetched popup")
    }

    @Test
    func missingFollowUpLoaderLeavesPopupModelUnchanged() async {
        let events = EventCapture()
        let controller = makeController(onLoadFollowUpPopupModel: nil, callback: events.record)
        controller.webViewPlacementModel = makePopupModel(title: "Existing popup")

        await controller.loadFollowUpPopupModel()

        #expect(controller.webViewPlacementModel?.overlayTitle.string == "Existing popup")
        #expect(events.eventCount == 0)
    }

    @Test
    func failedFetchLeavesMissingModelForActionFallback() async {
        let error = NSError(
            domain: "Transport",
            code: 503,
            userInfo: [NSLocalizedDescriptionKey: "service unavailable"]
        )
        let events = EventCapture()
        let controller = makeController(
            onLoadFollowUpPopupModel: { _ in throw error },
            callback: events.record
        )

        await controller.loadFollowUpPopupModel()
        controller.actionButtonTapped()

        #expect(events.eventCount == 2)
        guard case .actionButtonTapped = events.events[0],
            case let .sdkError(actionError) = events.events[1]
        else {
            Issue.record("Expected action event followed by missing-model fallback")
            return
        }
        #expect(actionError.localizedDescription == Constants.somethingWentWrong)
    }

    private func makeController(
        onLoadFollowUpPopupModel: (@MainActor @Sendable (String?) async throws -> PopupPlacementModel?)?,
        callback: @escaping @Sendable (BreadPartnerEvents) -> Void
    ) -> PopupController {
        PopupController(
            integrationKey: "brand-key",
            merchantConfiguration: MerchantConfiguration(),
            placementConfiguration: PlacementConfiguration(),
            popupModel: makePopupModel(title: "Offer"),
            overlayType: .singleProductOverlay,
            logger: Logger(),
            callback: callback,
            onLoadFollowUpPopupModel: onLoadFollowUpPopupModel
        )
    }

    private func makePopupModel(title: String) -> PopupPlacementModel {
        PopupPlacementModel(
            overlayType: "SINGLE_PRODUCT_OVERLAY",
            location: nil,
            brandLogoUrl: "",
            webViewUrl: "",
            overlayTitle: NSAttributedString(string: title),
            overlaySubtitle: NSAttributedString(string: ""),
            overlayContainerBarHeading: NSAttributedString(string: ""),
            bodyHeader: NSAttributedString(string: ""),
            primaryActionButtonAttributes: PrimaryActionButtonModel(
                dataContentFetch: "follow-up-fetch"
            ),
            dynamicBodyModel: PopupPlacementModel.DynamicBodyModel(bodyDiv: [:]),
            disclosure: NSAttributedString(string: ""),
            disclosureHTML: ""
        )
    }
}

private actor PopupModelFetcherSpy {
    private let model: PopupPlacementModel?
    private(set) var requestedIDs: [String?] = []

    init(model: PopupPlacementModel?) {
        self.model = model
    }

    func fetch(_ placementID: String?) -> PopupPlacementModel? {
        requestedIDs.append(placementID)
        return model
    }
}
