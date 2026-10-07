package enum AnalyticsEvent: String, CaseIterable, Sendable {
    case viewPlacement = "view-placement"
    case clickPlacement = "click-placement"

    package var endpoint: APIEndpoint {
        switch self {
        case .viewPlacement: .viewPlacement
        case .clickPlacement: .clickPlacement
        }
    }
}
