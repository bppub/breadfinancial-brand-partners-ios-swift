import Foundation

@testable import BreadPartners

enum RTPSTestFixtures {
    enum URLs {
        static let prescreen = URL(string: "https://rtps.test/api/prescreen")!
        static let virtualLookup = URL(string: "https://rtps.test/api/virtual_lookup")!
    }

    enum MerchantConfigurationFixture {
        static let complete = MerchantConfiguration(
            buyer: BreadPartnersBuyer(
                givenName: "Ada",
                familyName: "Lovelace",
                billingAddress: BreadPartnersAddress(
                    address1: "1 Main Street",
                    country: "US",
                    locality: "Columbus",
                    region: "OH",
                    postalCode: "43004"
                )
            ),
            env: .stage
        )
    }

    enum PlacementConfigurationFixture {
        static let rtps = PlacementConfiguration(rtpsData: RTPSData())
    }

    enum PopupPlacementModelFixture {
        static let embedded = PopupPlacementModel(
            overlayType: "EMBEDDED_OVERLAY",
            location: "checkout",
            brandLogoUrl: "https://assets.test/logo.png",
            webViewUrl: "https://embedded.test",
            overlayTitle: NSAttributedString(string: "Title"),
            overlaySubtitle: NSAttributedString(string: "Subtitle"),
            overlayContainerBarHeading: NSAttributedString(string: "Heading"),
            bodyHeader: NSAttributedString(string: "Body"),
            primaryActionButtonAttributes: nil,
            dynamicBodyModel: PopupPlacementModel.DynamicBodyModel(bodyDiv: [:]),
            disclosure: NSAttributedString(string: "Disclosure"),
            disclosureHTML: "<p>Disclosure</p>"
        )
    }

    enum Response {
        static let approved = RTPSResponse(
            returnCode: "01",
            prescreenId: 9001,
            cardType: "storeCard"
        )

        static let neutral = RTPSResponse()

        static let emptyPlacements = PlacementsResponse(
            placements: [],
            placementContent: nil
        )
    }

    enum Error {
        static let incapsula = NSError(
            domain: "IncapsulaChallenge",
            code: 0,
            userInfo: [
                "htmlContent": "<html>challenge</html>",
                "url": "https://challenge.test",
            ]
        )
    }
}
