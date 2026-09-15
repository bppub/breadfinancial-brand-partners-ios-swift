import Foundation

package protocol RTPSResponseDecoding: Sendable {
    func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data
    ) throws -> T
}
