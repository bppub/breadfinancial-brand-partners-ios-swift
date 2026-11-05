//------------------------------------------------------------------------------
//  File:          PopupChromeViewTests.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Testing
import UIKit
@testable import BreadPartners

@Suite
@MainActor
struct PopupChromeViewTests {
    @Test
    func installsPopupFrameAndConfiguresCloseButton() {
        let parentView = UIView()
        let chromeView = PopupChromeView(
            style: PopUpStyling(crossColor: .systemRed),
            configuration: PopupInput.ChromeConfiguration(logoURL: "", showsCloseButton: false),
            onClose: {}
        )

        chromeView.install(in: parentView)

        #expect(chromeView.superview === parentView)
        #expect(chromeView.backgroundColor == .white)
        #expect(chromeView.layer.cornerRadius == 12)
        #expect(chromeView.closeButton.isHidden)
        #expect(chromeView.closeButton.tintColor == .systemRed)
        #expect(parentView.constraints.count == 4)
    }

    @Test
    func closeButtonForwardsAction() {
        var closeCount = 0
        let chromeView = PopupChromeView(
            style: PopUpStyling(),
            configuration: PopupInput.ChromeConfiguration(logoURL: "", showsCloseButton: true),
            onClose: { closeCount += 1 }
        )

        chromeView.perform(NSSelectorFromString("closeButtonTapped"))

        #expect(closeCount == 1)
    }
}
