import Testing

@testable import BreadPartners

@Suite
@MainActor
struct RTPSUICoordinatorSpyTests {
    @Test
    func challengeRecordsEachInvocationWithoutPublishingEvents() {
        let coordinator = RTPSUICoordinatorSpy()
        let events = EventCapture()

        coordinator.presentChallenge(
            htmlContent: "challenge",
            originalURL: "https://challenge.test",
            callback: events.record,
            logger: Logger(),
            onComplete: { _ in }
        )
        coordinator.presentChallenge(
            htmlContent: "retry",
            originalURL: "https://retry.test",
            callback: events.record,
            logger: Logger(),
            onComplete: { _ in }
        )

        #expect(coordinator.challengeCallCount == 2)
        #expect(events.eventCount == 0)
    }

    @Test
    func failureRecordsTheLatestFailureWithoutPublishingEvents() {
        let coordinator = RTPSUICoordinatorSpy()
        let events = EventCapture()
        let failure = RTPSServiceFailure.api(message: "network failure")

        coordinator.presentFailure(failure, callback: events.record)

        #expect(coordinator.failureCallCount == 1)
        guard case let .api(message) = coordinator.lastFailure else {
            Issue.record("Expected the spy to retain the latest API failure")
            return
        }
        #expect(message == "network failure")
        #expect(events.eventCount == 0)
    }

    @Test
    func placementRecordsEachInvocationWithoutPublishingEvents() {
        let coordinator = RTPSUICoordinatorSpy()
        let events = EventCapture()
        let popupPlacementModel = RTPSTestFixtures.PopupPlacementModelFixture.embedded
        let merchantConfiguration = RTPSTestFixtures.MerchantConfigurationFixture.complete
        let placementsConfiguration = RTPSTestFixtures.PlacementConfigurationFixture.rtps

        coordinator.presentPlacement(
            popupPlacementModel,
            merchantConfiguration: merchantConfiguration,
            placementsConfiguration: placementsConfiguration,
            integrationKey: "integration-key",
            brandConfiguration: nil,
            logger: Logger(),
            callback: events.record
        )
        coordinator.presentPlacement(
            popupPlacementModel,
            merchantConfiguration: merchantConfiguration,
            placementsConfiguration: placementsConfiguration,
            integrationKey: "integration-key",
            brandConfiguration: nil,
            logger: Logger(),
            callback: events.record
        )

        #expect(coordinator.placementCallCount == 2)
        #expect(events.eventCount == 0)
    }
}
