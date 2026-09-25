import Foundation
import Testing
@testable import BreadPartners

@Suite
struct LiveAPIEndpointProviderTests {
    @Test
    func delegatesEndpointResolutionToAPIUrlForEachEnvironment() {
        let environments: [(BreadPartnersEnvironment, String, String)] = [
            (.stage, "https://brands.kmsmep.com", "https://acquire1stage.comenity.net"),
            (.prod, "https://brands.kmsmep.com", "https://acquire1.comenity.net"),
            (.uat, "https://brands.kmsmep.com", "https://acquire1uat.comenity.net"),
        ]

        for (environment, baseURL, rtpsBaseURL) in environments {
            let provider = LiveAPIEndpointProvider(environment: environment)

            let expectedURLs: [(APIEndpoint, String)] = [
                (.rtpsWebUrl(type: "lookup"), "\(rtpsBaseURL)/prescreen/lookup"),
                (.bpsWebUrl, "\(rtpsBaseURL)/batch-prescreen/start"),
                (.brandStyle(brandId: "brand-123"), "\(baseURL)/brands/brand-123/style"),
                (.brandConfig(brandId: "brand-123"), "\(baseURL)/brands/brand-123/config"),
                (.generatePlacements, "\(baseURL)/generatePlacements"),
                (.viewPlacement, "\(baseURL)/ep/v1/view-placement"),
                (.clickPlacement, "\(baseURL)/ep/v1/click-placement"),
                (.prescreen, "\(rtpsBaseURL)/api/prescreen"),
                (.virtualLookup, "\(rtpsBaseURL)/api/virtual_lookup"),
            ]

            for (endpoint, expectedURL) in expectedURLs {
                #expect(provider.url(for: endpoint) == URL(string: expectedURL))
            }
        }
    }
}
