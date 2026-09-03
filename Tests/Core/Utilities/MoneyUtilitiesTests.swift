import Testing
@testable import BreadPartnersCore

@Suite struct MoneyUtilitiesTests {
    @Test(
        "Converts cents to dollars",
        arguments: [
            (Int64.min, Double(Int64.min) / 100.0),
            (-12345, -123.45),
            (0, 0),
            (1, 0.01),
            (12345, 123.45),
            (Int64.max, Double(Int64.max) / 100.0),
        ]
    )
    func convertsCentsToDollars(cents: Int64, expectedDollars: Double) {
        #expect(fromMoneyToDollars(cents) == expectedDollars)
    }

    @Test
    func returnsNilForMissingMoneyValue() {
        #expect(fromMoneyToDollars(nil) == nil)
    }
}
