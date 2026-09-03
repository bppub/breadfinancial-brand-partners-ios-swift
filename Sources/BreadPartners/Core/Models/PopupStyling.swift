//------------------------------------------------------------------------------
//  File:          PlacementConfiguration.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

import UIKit

public struct PopUpStyling: @unchecked Sendable {
    public let loaderColor: UIColor
    public let crossColor: UIColor
    public let dividerColor: UIColor
    public let borderColor: CGColor
    public let backgroundColor: UIColor
    public let titlePopupTextStyle: PopupTextStyle
    public let subTitlePopupTextStyle: PopupTextStyle
    public let headerPopupTextStyle: PopupTextStyle
    public let headerBgColor: UIColor
    public let headingThreePopupTextStyle: PopupTextStyle
    public let paragraphPopupTextStyle: PopupTextStyle
    public let connectorPopupTextStyle: PopupTextStyle
    public let disclosurePopupTextStyle: PopupTextStyle
    public var actionButtonStyle: PopupActionButtonStyle?

    public init(
        loaderColor: UIColor = .black,
        crossColor: UIColor = .black,
        dividerColor: UIColor = BreadPartnerDefaults.LIGHT_GRAY_COLOR,
        borderColor: CGColor = BreadPartnerDefaults.LIGHT_GRAY_COLOR.cgColor,
        backgroundColor: UIColor = .white,
        titlePopupTextStyle: PopupTextStyle = BreadPartnerDefaults.TITLE_POPUP_TEXT_STYLE,
        subTitlePopupTextStyle: PopupTextStyle = BreadPartnerDefaults.SUBTITLE_POPUP_TEXT_STYLE,
        headerPopupTextStyle: PopupTextStyle = BreadPartnerDefaults.HEADER_POPUP_TEXT_STYLE,
        headerBgColor: UIColor = .lightGray.withAlphaComponent(0.5),
        headingThreePopupTextStyle: PopupTextStyle = BreadPartnerDefaults.HEADING_THREE_POPUP_TEXT_STYLE,
        paragraphPopupTextStyle: PopupTextStyle = BreadPartnerDefaults.PARAGRAPH_POPUP_TEXT_STYLE,
        connectorPopupTextStyle: PopupTextStyle = BreadPartnerDefaults.CONNECTOR_POPUP_TEXT_STYLE,
        disclosurePopupTextStyle: PopupTextStyle = BreadPartnerDefaults.DISCLOSURE_POPUP_TEXT_STYLE,
        actionButtonStyle: PopupActionButtonStyle? = nil
    ) {
        self.loaderColor = loaderColor
        self.crossColor = crossColor
        self.dividerColor = dividerColor
        self.borderColor = borderColor
        self.backgroundColor = backgroundColor
        self.titlePopupTextStyle = titlePopupTextStyle
        self.subTitlePopupTextStyle = subTitlePopupTextStyle
        self.headerPopupTextStyle = headerPopupTextStyle
        self.headerBgColor = headerBgColor
        self.headingThreePopupTextStyle = headingThreePopupTextStyle
        self.paragraphPopupTextStyle = paragraphPopupTextStyle
        self.connectorPopupTextStyle = connectorPopupTextStyle
        self.disclosurePopupTextStyle = disclosurePopupTextStyle
        self.actionButtonStyle = actionButtonStyle
    }
}

public struct PopupTextStyle: @unchecked Sendable {
    public var font: UIFont? = nil
    public var textColor: UIColor

    public init(
        font: UIFont? = nil,
        textColor: UIColor = BreadPartnerDefaults.GRAY_COLOR
    ) {
        self.font = font
        self.textColor = textColor
    }
}

public struct PopupActionButtonStyle {
    public var font: UIFont?
    public var textColor: UIColor?
    public var backgroundColor: UIColor?
    public var cornerRadius: CGFloat?
    public var padding: UIEdgeInsets?

    public init(
        font: UIFont? = nil,
        textColor: UIColor? = nil,
        backgroundColor: UIColor? = nil,
        cornerRadius: CGFloat? = nil,
        padding: UIEdgeInsets? = nil
    ) {
        self.font = font
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.padding = padding
    }
}
