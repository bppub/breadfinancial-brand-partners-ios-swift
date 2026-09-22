import Testing
@testable import BreadPartnersCore

@Suite
struct APIEndpointTests {
    @Test
    func buildsBrandAndPlacementURLs() {
        let endpoints: [(APIEndpoint, String)] = [
            (.brandStyle(brandId: "brand-123"), "https://brands.kmsmep.com/brands/brand-123/style"),
            (.brandConfig(brandId: "brand-123"), "https://brands.kmsmep.com/brands/brand-123/config"),
            (.generatePlacements, "https://brands.kmsmep.com/generatePlacements"),
            (.viewPlacement, "https://brands.kmsmep.com/ep/v1/view-placement"),
            (.clickPlacement, "https://brands.kmsmep.com/ep/v1/click-placement"),
        ]

        for (endpoint, expectedURL) in endpoints {
            #expect(endpoint.url(for: .prod) == expectedURL)
        }
    }

    @Test
    func buildsRTPSURLsForEachEnvironment() {
        let environments: [(BreadPartnersEnvironment, String)] = [
            (.stage, "https://acquire1stage.comenity.net"),
            (.prod, "https://acquire1.comenity.net"),
            (.uat, "https://acquire1uat.comenity.net"),
        ]

        for (environment, baseURL) in environments {
            #expect(
                APIEndpoint.rtpsWebUrl(type: "lookup").url(for: environment)
                    == "\(baseURL)/prescreen/lookup"
            )
            #expect(
                APIEndpoint.bpsWebUrl.url(for: environment)
                    == "\(baseURL)/batch-prescreen/start"
            )
            #expect(
                APIEndpoint.prescreen.url(for: environment)
                    == "\(baseURL)/api/prescreen"
            )
            #expect(
                APIEndpoint.virtualLookup.url(for: environment)
                    == "\(baseURL)/api/virtual_lookup"
            )
        }
    }
}
