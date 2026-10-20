import XCTest
import BreadPartners

/// Integration tests that exercise the real BreadPartnersSDK public API against
/// mocked HTTP responses via `MockURLProtocol`. Because the SDK uses
/// `URLSession.shared`, the protocol is registered globally in `setUp`.
final class PlacementIntegrationTests: XCTestCase {

    private let brandID = "test-brand"

    override func setUp() {
        super.setUp()
        MockURLProtocol.register()
    }

    override func tearDown() {
        MockURLProtocol.unregister()
        super.tearDown()
    }

    /// `setup()` should fetch brand config from the stubbed `/config` endpoint.
    func testSetupFetchesBrandConfig() async {
        SDKStubs.brandConfig(brandID: brandID)

        await BreadPartnersSDK.shared.setup(
            environment: .stage,
            integrationKey: brandID,
            enableLog: true
        )

        let paths = MockURLProtocol.capturedRequests.compactMap { $0.url?.path }
        XCTAssertTrue(
            paths.contains { $0.hasSuffix("/brands/\(brandID)/config") },
            "Expected setup() to request the brand config endpoint. Captured: \(paths)"
        )
    }

    /// `registerPlacements()` should hit `/generatePlacements` and fire the callback.
    func testRegisterPlacementsHitsPlacementsEndpoint() async {
        SDKStubs.happyPath(brandID: brandID)

        await BreadPartnersSDK.shared.setup(
            environment: .stage,
            integrationKey: brandID,
            enableLog: true
        )

        let callbackFired = expectation(description: "placement callback fired")
        callbackFired.assertForOverFulfill = false

        await BreadPartnersSDK.shared.registerPlacements(
            merchantConfiguration: MerchantConfiguration(env: .stage),
            placementsConfiguration: PlacementConfiguration(
                placementData: PlacementData(
                    financingType: nil,
                    locationType: nil,
                    placementId: "placement-1",
                    domID: "123"
                )
            ),
            forSwiftUI: true
        ) { _ in
            callbackFired.fulfill()
        }

        await fulfillment(of: [callbackFired], timeout: 5)

        let paths = MockURLProtocol.capturedRequests.compactMap { $0.url?.path }
        XCTAssertTrue(
            paths.contains { $0.hasSuffix("/generatePlacements") },
            "Expected registerPlacements() to request /generatePlacements. Captured: \(paths)"
        )
    }

    /// A transport failure on `/generatePlacements` should surface an SDK error.
    func testPlacementNetworkFailureReportsSDKError() async {
        SDKStubs.brandConfig(brandID: brandID)
        MockURLProtocol.stub(
            where: { $0.url?.path.hasSuffix("/generatePlacements") ?? false },
            data: Data(),
            error: URLError(.timedOut)
        )

        await BreadPartnersSDK.shared.setup(
            environment: .stage,
            integrationKey: brandID,
            enableLog: true
        )

        let errorReported = expectation(description: "sdk error reported")
        errorReported.assertForOverFulfill = false

        await BreadPartnersSDK.shared.registerPlacements(
            merchantConfiguration: MerchantConfiguration(env: .stage),
            placementsConfiguration: PlacementConfiguration(
                placementData: PlacementData(
                    financingType: nil,
                    locationType: nil,
                    placementId: "placement-1",
                    domID: "123"
                )
            ),
            forSwiftUI: true
        ) { event in
            if case .sdkError = event {
                errorReported.fulfill()
            }
        }

        await fulfillment(of: [errorReported], timeout: 5)
    }
}
