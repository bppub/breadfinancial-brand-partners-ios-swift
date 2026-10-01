import Foundation

package protocol BrandConfigurationResponseDecoding: Sendable {
    func decode(from data: Data) throws -> BrandConfiguration
}
