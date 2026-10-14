import BreadPartnersCore
import Foundation

final class PlacementCoordinator: PlacementCoordinating {
    private let environment: BreadPartnersEnvironment
    private let endpointProvider: any APIEndpointProviding
    private let makeUICoordinator: @MainActor @Sendable () -> any PlacementUICoordinating

    init(
        environment: BreadPartnersEnvironment,
        endpointProvider: any APIEndpointProviding,
        makeUICoordinator: @escaping @MainActor @Sendable () -> any PlacementUICoordinating = {
            PlacementUICoordinator.live
        }
    ) {
        self.environment = environment
        self.endpointProvider = endpointProvider
        self.makeUICoordinator = makeUICoordinator
    }

    func runFlow(_ input: PlacementCoordinatorInput) async {
        await execute(input, cookies: nil)
    }

    private func execute(_ input: PlacementCoordinatorInput, cookies: String?) async {
        let uiCoordinator = await makeUICoordinator()
        let outcome = await PlacementService().execute(
            PlacementServiceInput(
                httpClient: input.httpClient,
                request: PlacementRequestBuilder(
                    integrationKey: input.integrationKey,
                    merchantConfiguration: input.merchantConfiguration,
                    placementConfig: input.placementsConfiguration.placementData,
                    environment: environment
                ).build(),
                url: endpointProvider.url(for: .generatePlacements),
                cookies: cookies
            )
        )

        switch outcome {
        case let .success(response):
            await uiCoordinator.presentPlacement(
                response,
                input: input
            )

        case let .challenge(htmlContent, originalURL, _):
            await uiCoordinator.presentChallenge(
                htmlContent: htmlContent,
                originalURL: originalURL,
                callback: input.callback,
                logger: input.logger,
                onComplete: { [self] cookie in
                    Task {
                        await execute(input, cookies: cookie)
                    }
                }
            )

        case let .failure(error):
            await uiCoordinator.presentFailure(error, callback: input.callback)
        }
    }
}
