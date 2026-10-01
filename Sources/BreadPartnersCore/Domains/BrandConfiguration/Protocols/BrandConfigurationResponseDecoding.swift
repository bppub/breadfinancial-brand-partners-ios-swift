import Foundation

protocol BrandConfigurationResponseDecoding: Sendable {
    func decode(from data: Data) throws -> BrandConfiguration
}
