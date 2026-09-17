import BreadPartnersCore
import Foundation

package struct LiveRTPSResponseDecoder: RTPSResponseDecoding {
    package func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data
    ) throws -> T {
        try JSONDecoder().decode(type, from: data)
    }
}
