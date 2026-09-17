import Foundation
import Testing
@testable import BreadPartners

@Suite(.serialized)
struct APIUrlTests {
    @Test
    func buildsBrandAndPlacementURLs() async {
        #expect(
            APIUrl(
                urlType: .brandStyle(brandId: "brand-123"),
                environment: .prod
            ).url
                == "https://brands.kmsmep.com/brands/brand-123/style"
        )
        #expect(
            APIUrl(
                urlType: .brandConfig(brandId: "brand-123"),
                environment: .prod
            ).url
                == "https://brands.kmsmep.com/brands/brand-123/config"
        )
        #expect(
            APIUrl(urlType: .generatePlacements, environment: .prod).url
                == "https://brands.kmsmep.com/generatePlacements"
        )
        #expect(
            APIUrl(urlType: .viewPlacement, environment: .prod).url
                == "https://brands.kmsmep.com/ep/v1/view-placement"
        )
        #expect(
            APIUrl(urlType: .clickPlacement, environment: .prod).url
                == "https://brands.kmsmep.com/ep/v1/click-placement"
        )
    }

    @Test
    func buildsRTPSURLsForEachEnvironment() async {
        let environments: [(BreadPartnersEnvironment, String)] = [
            (.stage, "https://acquire1stage.comenity.net"),
            (.prod, "https://acquire1.comenity.net"),
            (.uat, "https://acquire1uat.comenity.net"),
        ]

        for (environment, baseURL) in environments {
            #expect(
                APIUrl(
                    urlType: .rtpsWebUrl(type: "lookup"),
                    environment: environment
                ).url
                    == "\(baseURL)/prescreen/lookup"
            )
            #expect(
                APIUrl(urlType: .bpsWebUrl, environment: environment).url
                    == "\(baseURL)/batch-prescreen/start"
            )
            #expect(
                APIUrl(urlType: .prescreen, environment: environment).url
                    == "\(baseURL)/api/prescreen"
            )
            #expect(
                APIUrl(urlType: .virtualLookup, environment: environment).url
                    == "\(baseURL)/api/virtual_lookup"
            )
        }
    }

    @Test
    func foundationURLMatchesGeneratedURL() {
        let urls = [
            APIUrl(urlType: .brandConfig(brandId: "brand-123"), environment: .prod),
            APIUrl(urlType: .prescreen, environment: .stage),
            APIUrl(urlType: .generatePlacements, environment: .uat),
        ]

        for apiURL in urls {
            #expect(apiURL.foundationURL == URL(string: apiURL.url))
        }
    }

    @Test
    func setEnvironmentUpdatesCurrentEnvironmentForLegacyCallers() async {
        await APIUrl.setEnvironment(.uat)

        #expect(APIUrl.currentEnvironment == .uat)
        #expect(
            APIUrl(urlType: .prescreen).url
                == "https://acquire1uat.comenity.net/api/prescreen"
        )

        await APIUrl.setEnvironment(.prod)
        #expect(APIUrl.currentEnvironment == .prod)
    }
}
