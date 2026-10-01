package struct BrandConfigurationService: BrandConfigurationServicing {
    private let dependencies: BrandConfigurationDependencies

    package init(dependencies: BrandConfigurationDependencies) {
        self.dependencies = dependencies
    }

    package func fetch(
        brandID: String,
        httpClient: any HTTPClient
    ) async -> BrandConfiguration? {
        do {
            let data = try await httpClient.request(
                HTTPRequest(
                    url: dependencies.endpointProvider.url(
                        for: .brandConfig(brandId: brandID)
                    ),
                    method: .GET
                )
            )

            return try dependencies.responseDecoder.decode(from: data)
        } catch {
            return nil
        }
    }
}
