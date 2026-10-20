import Foundation

/// Reusable fixture sets for the endpoints the BreadPartners SDK hits.
///
/// Endpoints (matched by path suffix):
///   /brands/{id}/config      – brand config, fetched during `setup()`
///   /brands/{id}/style       – brand style
///   /generatePlacements      – placements
///   /ep/v1/view-placement    – analytics (view)
///   /ep/v1/click-placement   – analytics (click)
enum SDKStubs {

    /// Minimal brand config. All fields decode as optional in the SDK, so an
    /// empty config object is enough for `setup()` to complete cleanly.
    static func brandConfig(brandID: String) {
        MockURLProtocol.stub(path: "/brands/\(brandID)/config", json: #"{ "config": {} }"#)
        MockURLProtocol.stub(path: "/brands/\(brandID)/style", json: #"{ "config": {} }"#)
    }

    /// Happy path: `setup()` + `registerPlacements()` return a text placement.
    static func happyPath(brandID: String, placementsJSON: String = Self.emptyPlacements) {
        brandConfig(brandID: brandID)
        MockURLProtocol.stub(path: "/generatePlacements", json: placementsJSON)

        // Analytics are fire-and-forget; stub so they don't fail loudly.
        MockURLProtocol.stub(path: "/ep/v1/view-placement", json: "{}")
        MockURLProtocol.stub(path: "/ep/v1/click-placement", json: "{}")
    }

    /// A placements response with no placements (callback resolves without UI).
    static let emptyPlacements = #"{ "placements": [], "placementContent": [] }"#
}
