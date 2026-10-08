import BreadPartnersCore
import Testing

@Suite
struct PlacementActionTypeTests {
    @Test(
        arguments: [
            ("SHOW_OVERLAY", .showOverlay),
            ("REDIRECT", .redirect),
            ("BREAD_APPLY", .breadApply),
            ("REDIRECT_INTERNAL", .redirectInternal),
            ("VERSATILE_ECO", .versatileEco),
            ("NO_ACTION", .noAction),
            ("show_overlay", nil),
            ("UNKNOWN", nil),
            ("", nil),
        ] as [(String, PlacementActionType?)])
    func mapsServerActionTypeStrings(rawValue: String, expected: PlacementActionType?) {
        #expect(PlacementActionType(rawValue: rawValue) == expected)
    }
}
