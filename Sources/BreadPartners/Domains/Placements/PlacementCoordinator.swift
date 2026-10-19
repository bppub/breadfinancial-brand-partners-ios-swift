//------------------------------------------------------------------------------
//  File:          PlacementCoordinator.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import BreadPartnersCore
import Foundation

final class PlacementCoordinator: PlacementCoordinating {
    private let environment: BreadPartnersEnvironment
    private let endpointProvider: any APIEndpointProviding
    private let placementService: any PlacementServicing
    private let makeUICoordinator: @MainActor @Sendable () -> any PlacementUICoordinating

    init(
        environment: BreadPartnersEnvironment,
        endpointProvider: any APIEndpointProviding,
        placementService: any PlacementServicing = PlacementService(),
        makeUICoordinator: @escaping @MainActor @Sendable () -> any PlacementUICoordinating = {
            PlacementUICoordinator.live
        }
    ) {
        self.environment = environment
        self.endpointProvider = endpointProvider
        self.placementService = placementService
        self.makeUICoordinator = makeUICoordinator
    }

    func runFlow(_ input: PlacementCoordinatorInput) async {
        await execute(input, cookies: nil)
    }

    private func execute(_ input: PlacementCoordinatorInput, cookies: String?) async {
        let uiCoordinator = await makeUICoordinator()
        let serviceInput = PlacementServiceInput(
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

        let outcome = await placementService.execute(serviceInput)

        switch outcome {
        case let .success(response):
            await uiCoordinator.presentPlacement(
                response,
                input: input,
                onFetchFollowUpPlacement: makeFollowUpPlacementFetcher(
                    service: placementService,
                    serviceInput: serviceInput,
                    callback: input.callback
                )
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

    private func makeFollowUpPlacementFetcher(
        service: any PlacementServicing,
        serviceInput: PlacementServiceInput,
        callback: @escaping @Sendable (BreadPartnerEvents) -> Void
    ) -> @MainActor @Sendable (String?) async throws -> PlacementsResponse {
        return { placementID in
            let outcome = await service.execute(
                serviceInput.forFollowUpPlacement(placementID: placementID)
            )

            switch outcome {
            case let .success(response):
                return response

            case let .challenge(_, _, error), let .failure(error):
                callback(
                    .sdkError(
                        error: NSError(
                            domain: "",
                            code: 500,
                            userInfo: [
                                NSLocalizedDescriptionKey: Constants.apiError(
                                    message: error.localizedDescription
                                )
                            ]
                        )
                    )
                )
                throw error
            }
        }
    }
}

private extension PlacementServiceInput {
    func forFollowUpPlacement(placementID: String?) -> PlacementServiceInput {
        PlacementServiceInput(
            httpClient: httpClient,
            request: PlacementRequest(
                placements: [
                    PlacementRequestBody(
                        id: placementID,
                        context: request.placements?.first?.context
                    )
                ],
                brandId: request.brandId
            ),
            url: url,
            cookies: cookies
        )
    }
}
