package struct PlacementConfigurationData: @unchecked Sendable {
    package let placementData: PlacementData?
    package let rtpsData: RTPSData?

    package init(
        placementData: PlacementData? = nil,
        rtpsData: RTPSData? = nil
    ) {
        self.placementData = placementData
        self.rtpsData = rtpsData
    }
}
