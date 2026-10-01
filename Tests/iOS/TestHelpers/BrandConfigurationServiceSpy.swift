import BreadPartnersCore

actor BrandConfigurationServiceSpy: BrandConfigurationServicing {
    private var results: [BrandConfiguration?]
    private(set) var requestedBrandIDs: [String] = []

    init(results: [BrandConfiguration?]) {
        self.results = results
    }

    package func fetch(
        brandID: String,
        httpClient: any HTTPClient
    ) async -> BrandConfiguration? {
        requestedBrandIDs.append(brandID)
        guard !results.isEmpty else { return nil }
        return results.removeFirst()
    }
}
