package protocol BrandConfigurationServicing: Sendable {
    func fetch(
        brandID: String,
        httpClient: any HTTPClient
    ) async -> BrandConfiguration?
}
