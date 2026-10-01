import BreadPartnersCore
import Foundation

struct RealTimePrescreenInput: @unchecked Sendable {
    let merchantConfiguration: MerchantConfiguration
    let placementsConfiguration: PlacementConfiguration
    let integrationKey: String
    let brandConfiguration: BrandConfiguration?
    let splitTextAndAction: Bool
    let openPlacementExperience: Bool
    let forSwiftUI: Bool
    let logger: Logger
    let callback: @Sendable (BreadPartnerEvents) -> Void

    func withResponseUpdates(_ response: RTPSResponse) -> Self {
        var updatedPlacementsConfiguration = placementsConfiguration
        updatedPlacementsConfiguration.rtpsData?.prescreenId = response.prescreenId
        updatedPlacementsConfiguration.rtpsData?.cardType = response.cardType

        return Self(
            merchantConfiguration: response.updateMerchantConfiguration(
                merchantConfiguration
            ),
            placementsConfiguration: updatedPlacementsConfiguration,
            integrationKey: integrationKey,
            brandConfiguration: brandConfiguration,
            splitTextAndAction: splitTextAndAction,
            openPlacementExperience: openPlacementExperience,
            forSwiftUI: forSwiftUI,
            logger: logger,
            callback: callback
        )
    }
}

protocol RealTimePrescreenCoordinating: Sendable {
    func runFlow(_ input: RealTimePrescreenInput) async
}
