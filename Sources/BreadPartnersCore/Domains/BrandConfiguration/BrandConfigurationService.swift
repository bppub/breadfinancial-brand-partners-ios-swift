import BreadPartnersCore

struct BrandConfigurationService: BrandConfigurationServicing {
    private let dependencies: BrandConfigurationDependencies

    init(dependencies: BrandConfigurationDependencies) {
        self.dependencies = dependencies
    }

    func fetch(brandID: String) async -> BrandConfiguration? {
        do {
            let data = try await dependencies.httpClient.request(
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
