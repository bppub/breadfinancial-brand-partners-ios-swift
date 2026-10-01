package protocol BrandConfigurationServicing: Sendable {
    func fetch(brandID: String) async -> BrandConfiguration?
}
