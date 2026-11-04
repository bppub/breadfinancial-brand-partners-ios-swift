//------------------------------------------------------------------------------
//  File:          PopupStylingTests.swift
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
struct PopupStylingTests {
    @Test
    func popupStylingUsesInitializerDefaults() {
        let style = PopUpStyling()

        #expect(style.loaderColor == .black)
        #expect(style.crossColor == .black)
        #expect(style.dividerColor == BreadPartnerDefaults.LIGHT_GRAY_COLOR)
        #expect(
            style.borderColor == BreadPartnerDefaults.LIGHT_GRAY_COLOR.cgColor
        )
        #expect(style.backgroundColor == .white)
        #expect(style.headerBgColor == UIColor.lightGray.withAlphaComponent(0.5))
        #expect(style.titlePopupTextStyle.font == BreadPartnerDefaults.TITLE_POPUP_TEXT_STYLE.font)
        #expect(style.subTitlePopupTextStyle.font == BreadPartnerDefaults.SUBTITLE_POPUP_TEXT_STYLE.font)
        #expect(style.actionButtonStyle == nil)
    }

    @Test
    func popupStylingPreservesCustomValues() {
        let titleStyle = PopupTextStyle(
            font: .italicSystemFont(ofSize: 18),
            textColor: .systemRed
        )
        let actionButtonStyle = PopupActionButtonStyle(
            textColor: .white,
            backgroundColor: .systemBlue,
            cornerRadius: 4
        )
        let style = PopUpStyling(
            loaderColor: .systemGreen,
            crossColor: .systemOrange,
            titlePopupTextStyle: titleStyle,
            actionButtonStyle: actionButtonStyle
        )

        #expect(style.loaderColor == .systemGreen)
        #expect(style.crossColor == .systemOrange)
        #expect(style.titlePopupTextStyle.font?.pointSize == 18)
        #expect(style.titlePopupTextStyle.textColor == .systemRed)
        #expect(style.actionButtonStyle?.textColor == .white)
        #expect(style.actionButtonStyle?.backgroundColor == .systemBlue)
        #expect(style.actionButtonStyle?.cornerRadius == 4)
    }

    @Test
    func popupTextStyleDefaultsAndPreservesOverrides() {
        let defaultStyle = PopupTextStyle()
        let customStyle = PopupTextStyle(
            font: .italicSystemFont(ofSize: 16),
            textColor: .systemBlue
        )

        #expect(defaultStyle.font == nil)
        #expect(defaultStyle.textColor == BreadPartnerDefaults.GRAY_COLOR)
        #expect(customStyle.font?.pointSize == 16)
        #expect(customStyle.textColor == .systemBlue)
    }
}
