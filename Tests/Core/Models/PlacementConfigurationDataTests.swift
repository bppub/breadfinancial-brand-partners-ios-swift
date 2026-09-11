import Testing
@testable import BreadPartnersCore

@Suite struct PlacementConfigurationDataTests {
    @Test
    func defaultsToNilValues() {
        let configuration = PlacementConfigurationData()

        #expect(configuration.placementData == nil)
        #expect(configuration.rtpsData == nil)
    }

    @Test
    func preservesProvidedModelReferences() {
        let order = Order(totalPrice: CurrencyValue(currency: "USD", value: 1500))
        let placementData = PlacementData(order: order)
        let rtpsData = RTPSData(order: order)
        let configuration = PlacementConfigurationData(
            placementData: placementData,
            rtpsData: rtpsData
        )

        #expect(configuration.placementData === placementData)
        #expect(configuration.rtpsData === rtpsData)
        configuration.placementData?.order?.totalPrice?.value = 1999
        #expect(configuration.rtpsData?.order?.totalPrice?.value == 1999)
    }
}
