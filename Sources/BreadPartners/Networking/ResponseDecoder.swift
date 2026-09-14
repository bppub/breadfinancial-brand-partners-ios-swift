import BreadPartnersCore
import Foundation

internal enum ResponseDecoder {
    static func decode<T: Decodable>(_ response: Any, as type: T.Type) throws -> T {
        let payload = (response as? AnySendable)?.value ?? response
        return try BreadPartnersCore.decodeJSON(from: payload, to: type)
    }
}
