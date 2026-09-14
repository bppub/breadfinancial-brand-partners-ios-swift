import Testing
@testable import BreadPartnersSDKCore

@Suite struct OptionalStringExtensionsTests {
    @Test(
        "Filters missing or blank strings",
        arguments: [String?.none, "", " ", "\n\t"]
    )
    func filtersMissingOrBlankStrings(value: String?) {
        #expect(value.takeIfNotEmpty() == nil)
    }

    @Test(arguments: [String?("value"), "  value  ", "value\n"])
    func preservesNonblankString(value: String?) {
        #expect(value.takeIfNotEmpty() == value)
    }
}
