import UIKit

internal enum PopupStylingDefaults {
    static let grayColor = UIColor(hex: "#767676")
    static let lightGrayColor = UIColor(hex: "#ececec")
    static let titleTextStyle = PopupTextStyle(
        font: UIFont(name: "Arial-BoldMT", size: 16.0),
        textColor: .black
    )
    static let subtitleTextStyle = PopupTextStyle(
        font: UIFont(name: "Arial-BoldMT", size: 12.0),
        textColor: grayColor
    )
    static let headerTextStyle = PopupTextStyle(
        font: UIFont(name: "Arial-BoldMT", size: 14.0),
        textColor: .black
    )
    static let headingThreeTextStyle = PopupTextStyle(
        font: UIFont(name: "Arial-BoldMT", size: 14.0),
        textColor: .black
    )
    static let paragraphTextStyle = PopupTextStyle(
        font: UIFont(name: "Arial-BoldMT", size: 10.0),
        textColor: grayColor
    )
    static let connectorTextStyle = PopupTextStyle(
        font: UIFont(name: "Arial-BoldMT", size: 14.0),
        textColor: .black
    )
    static let disclosureTextStyle = PopupTextStyle(
        font: UIFont(name: "Arial-BoldMT", size: 10.0),
        textColor: grayColor
    )
    static let popupStyle = PopUpStyling(
        loaderColor: UIColor(hex: "#0f2233"),
        crossColor: .black,
        dividerColor: lightGrayColor,
        borderColor: lightGrayColor.cgColor,
        titlePopupTextStyle: titleTextStyle,
        subTitlePopupTextStyle: subtitleTextStyle,
        headerPopupTextStyle: headerTextStyle,
        headerBgColor: lightGrayColor,
        headingThreePopupTextStyle: headingThreeTextStyle,
        paragraphPopupTextStyle: paragraphTextStyle,
        connectorPopupTextStyle: connectorTextStyle,
        disclosurePopupTextStyle: disclosureTextStyle,
        actionButtonStyle: PopupActionButtonStyle(
            font: UIFont.boldSystemFont(ofSize: 18),
            textColor: .white,
            backgroundColor: .black,
            cornerRadius: 8.0,
            padding: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        )
    )
}
