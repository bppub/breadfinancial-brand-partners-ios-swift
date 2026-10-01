import Foundation

package enum APIEndpoint: Sendable {
    case rtpsWebUrl(type: String)
    case bpsWebUrl
    case brandStyle(brandId: String)
    case brandConfig(brandId: String)
    case generatePlacements
    case viewPlacement
    case clickPlacement
    case prescreen
    case virtualLookup

    package func url(for environment: BreadPartnersEnvironment) -> String {
        let baseURL = "https://brands.kmsmep.com"
        let rtpsBaseURL: String

        switch environment {
        case .stage:
            rtpsBaseURL = "https://acquire1stage.comenity.net"
        case .prod:
            rtpsBaseURL = "https://acquire1.comenity.net"
        case .uat:
            rtpsBaseURL = "https://acquire1uat.comenity.net"
        }

        switch self {
        case let .rtpsWebUrl(type):
            return "\(rtpsBaseURL)/prescreen/\(type)"
        case .bpsWebUrl:
            return "\(rtpsBaseURL)/batch-prescreen/start"
        case let .brandStyle(brandId):
            return "\(baseURL)/brands/\(brandId)/style"
        case let .brandConfig(brandId):
            return "\(baseURL)/brands/\(brandId)/config"
        case .generatePlacements:
            return "\(baseURL)/generatePlacements"
        case .viewPlacement:
            return "\(baseURL)/ep/v1/view-placement"
        case .clickPlacement:
            return "\(baseURL)/ep/v1/click-placement"
        case .prescreen:
            return "\(rtpsBaseURL)/api/prescreen"
        case .virtualLookup:
            return "\(rtpsBaseURL)/api/virtual_lookup"
        }
    }
}
