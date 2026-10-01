import BreadPartnersCore

protocol BrandConfigurationServiceFactory: Sendable {
    func makeService(httpClient: any HTTPClient) -> any BrandConfigurationServicing
}
