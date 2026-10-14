import BreadPartnersCore

struct PlacementCoordinatorInput: Sendable {
    let httpClient: any HTTPClient
    let analyticsReporter: any AnalyticsReporting
    let integrationKey: String
    let merchantConfiguration: MerchantConfiguration
    let placementsConfiguration: PlacementConfiguration
    let splitTextAndAction: Bool
    let openPlacementExperience: Bool
    let forSwiftUI: Bool
    let logger: Logger
    let callback: @Sendable (BreadPartnerEvents) -> Void
}

protocol PlacementCoordinating: Sendable {
    func runFlow(_ input: PlacementCoordinatorInput) async
}
