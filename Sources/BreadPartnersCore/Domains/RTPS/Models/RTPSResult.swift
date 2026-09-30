package enum RTPSResult: Sendable, Equatable {
    case accountFound
    case approved
    case noHit
    case makeOffer
    case acknowledge

    private static let returnCodeMap: [String: RTPSResult] = [
        "0": .accountFound,
        "01": .approved,
        "10": .noHit,
        "11": .makeOffer,
        "12": .acknowledge,
    ]

    package init(returnCode: String?) {
        guard let returnCode else {
            self = .noHit
            return
        }

        self = Self.returnCodeMap[returnCode] ?? .noHit
    }
}
