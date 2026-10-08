package struct TextPlacementModel: Sendable {
    package let actionType: String?
    package let actionTarget: String?
    package let contentText: String?
    package let actionLink: String?
    package let actionContentId: String?
    package let htmlContent: String?

    package init(
        actionType: String?,
        actionTarget: String?,
        contentText: String?,
        actionLink: String?,
        actionContentId: String?,
        htmlContent: String?
    ) {
        self.actionType = actionType
        self.actionTarget = actionTarget
        self.contentText = contentText
        self.actionLink = actionLink
        self.actionContentId = actionContentId
        self.htmlContent = htmlContent
    }
}

package enum PlacementActionType: String, Sendable {
    case showOverlay = "SHOW_OVERLAY"
    case redirect = "REDIRECT"
    case breadApply = "BREAD_APPLY"
    case redirectInternal = "REDIRECT_INTERNAL"
    case versatileEco = "VERSATILE_ECO"
    case noAction = "NO_ACTION"
}
