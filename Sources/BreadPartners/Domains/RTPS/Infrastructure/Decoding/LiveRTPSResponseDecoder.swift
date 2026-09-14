import BreadPartnersCore
import Foundation

package struct LiveRTPSResponseDecoder: RTPSResponseDecoding {
    package init() {}

    package func decode<T: Decodable>(
        _ type: T.Type,
        from response: RTPSNetworkResponse
    ) throws -> T {
        try JSONDecoder().decode(type, from: response.data)
    }
}
