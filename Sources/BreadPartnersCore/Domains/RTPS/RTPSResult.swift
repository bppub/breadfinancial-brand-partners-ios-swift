package enum RTPSResult: Sendable, Equatable {
    case accountFound
    case approved
    case noHit
    case makeOffer
    case acknowledge

    package init(returnCode: String?) {
        switch returnCode {
        case "0":
            self = .accountFound
        case "01":
            self = .approved
        case "11":
            self = .makeOffer
        case "12":
            self = .acknowledge
        default:
            self = .noHit
        }
    }
}

package func getPrescreenResult(from apiResponse: String) -> RTPSResult {
    RTPSResult(returnCode: apiResponse)
}
