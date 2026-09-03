import Testing
import UIKit
@testable import BreadPartners

@Suite struct PlacementConfigurationTests {
    @Test
    func defaultsToNilValues() {
        let configuration = PlacementConfiguration()

        #expect(configuration.placementData == nil)
        #expect(configuration.rtpsData == nil)
        #expect(configuration.popUpStyling == nil)
    }

    @Test
    func preservesCoreModelsAndCustomStyle() {
        let placementData = PlacementData(placementId: "placement-1")
        let rtpsData = RTPSData(prescreenId: 42)
        let style = PopUpStyling(loaderColor: .red)
        var configuration = PlacementConfiguration(
            placementData: placementData,
            rtpsData: rtpsData,
            popUpStyling: style
        )

        #expect(configuration.placementData === placementData)
        #expect(configuration.rtpsData === rtpsData)
        #expect(configuration.popUpStyling?.loaderColor == .red)

        configuration.popUpStyling = PopUpStyling(loaderColor: .blue)
        #expect(configuration.popUpStyling?.loaderColor == .blue)
    }

    @Test
    func popupActionButtonStylePreservesFields() {
        let padding = UIEdgeInsets(top: 8, left: 16, bottom: 12, right: 20)
        let style = PopupActionButtonStyle(
            font: .italicSystemFont(ofSize: 18),
            textColor: .yellow,
            backgroundColor: .black,
            cornerRadius: 3,
            padding: padding
        )

        #expect(style.font?.pointSize == 18)
        #expect(style.font?.fontDescriptor.symbolicTraits.contains(.traitItalic) == true)
        #expect(style.textColor == .yellow)
        #expect(style.backgroundColor == .black)
        #expect(style.cornerRadius == 3)
        #expect(style.padding == padding)
    }

    @Test
    func legacyDefaultsForwardExpectedValues() throws {
        #expect(try colorComponents(BreadPartnerDefaults.GRAY_COLOR) == [118, 118, 118, 255])
        #expect(try colorComponents(BreadPartnerDefaults.LIGHT_GRAY_COLOR) == [236, 236, 236, 255])
        #expect(BreadPartnerDefaults.TITLE_POPUP_TEXT_STYLE.font?.pointSize == 16)
        #expect(BreadPartnerDefaults.SUBTITLE_POPUP_TEXT_STYLE.font?.pointSize == 12)
        #expect(BreadPartnerDefaults.HEADER_POPUP_TEXT_STYLE.font?.pointSize == 14)
        #expect(BreadPartnerDefaults.HEADING_THREE_POPUP_TEXT_STYLE.font?.pointSize == 14)
        #expect(BreadPartnerDefaults.PARAGRAPH_POPUP_TEXT_STYLE.font?.pointSize == 10)
        #expect(BreadPartnerDefaults.CONNECTOR_POPUP_TEXT_STYLE.font?.pointSize == 14)
        #expect(BreadPartnerDefaults.DISCLOSURE_POPUP_TEXT_STYLE.font?.pointSize == 10)
        #expect(BreadPartnerDefaults.popupStyle.actionButtonStyle?.cornerRadius == 8)
    }

    private func colorComponents(_ color: UIColor) throws -> [Int] {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        #expect(color.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        return [red, green, blue, alpha].map { Int(($0 * 255).rounded()) }
    }
}
