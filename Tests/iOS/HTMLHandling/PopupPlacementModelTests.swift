//------------------------------------------------------------------------------
//  File:          PopupPlacementModelTests.swift
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
import Testing

@testable import BreadPartners

@Suite
struct PopupPlacementModelTests {
    @Test
    func initializesAttributesFromPopupHTMLParserModel() {
        let attributes = PopupPlacementHTMLModel.PrimaryActionButton(
            dataOverlayType: "EMBEDDED_OVERLAY",
            dataContentFetch: "content-fetch",
            dataActionTarget: "target",
            dataActionType: "SHOW_OVERLAY",
            dataActionContentId: "content-id",
            dataLocation: "checkout",
            buttonText: "Continue"
        )

        let model = PrimaryActionButtonModel(attributes)

        #expect(model.dataOverlayType == attributes.dataOverlayType)
        #expect(model.dataContentFetch == attributes.dataContentFetch)
        #expect(model.dataActionTarget == attributes.dataActionTarget)
        #expect(model.dataActionType == attributes.dataActionType)
        #expect(model.dataActionContentId == attributes.dataActionContentId)
        #expect(model.dataLocation == attributes.dataLocation)
        #expect(model.buttonText == attributes.buttonText)
    }

    @Test
    func memberwiseInitializerPreservesValuesAndDefaultsUnspecifiedAttributesToNil() {
        let model = PrimaryActionButtonModel(
            dataContentFetch: "content-fetch",
            dataActionType: "SHOW_OVERLAY",
            buttonText: "Continue"
        )

        #expect(model.dataOverlayType == nil)
        #expect(model.dataContentFetch == "content-fetch")
        #expect(model.dataActionTarget == nil)
        #expect(model.dataActionType == "SHOW_OVERLAY")
        #expect(model.dataActionContentId == nil)
        #expect(model.dataLocation == nil)
        #expect(model.buttonText == "Continue")
    }
}
