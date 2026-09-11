//------------------------------------------------------------------------------
//  File:          Logger.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

import Foundation

/// Class responsible for logging information for debugging and tracking purposes.
internal class Logger: NSObject, @unchecked Sendable {

    static let shared = Logger()

    override init() {
        super.init()
    }

    private(set) var isLoggingEnabled: Bool = false
    private(set) var callback: (BreadPartnerEvents) -> Void = { _ in }
    private let coreLogger = CoreLogger()

    let dashLineFifty = String(repeating: "-", count: 50)
    let dashLineFifteen = String(repeating: "-", count: 15)
    let dashLineTen = String(repeating: "-", count: 10)

    func setLogging(enabled: Bool) {
        self.isLoggingEnabled = enabled
        coreLogger.isEnabled = enabled
    }

    func setCallback(_ newCallback: @escaping (BreadPartnerEvents) -> Void) {
        self.callback = newCallback
        coreLogger.sink = { [weak self] message in
            self?.callback(.onSDKEventLog(logs: message))
        }
    }

    nonisolated public func debugPrint(
        _ items: Any..., separator: String = " ", terminator: String = "\n"
    ) {
        coreLogger.emit(items, separator: separator, terminator: terminator)
    }

    func printLog(
        _ items: Any..., separator: String = " ", terminator: String = "\n"
    ) {
        guard isLoggingEnabled else { return }
        debugPrint(items)
    }
    func logRequestDetails(
        url: URL,
        method: String,
        headers: [String: String]?,
        body: Data?
    ) {
        guard isLoggingEnabled else { return }

        debugPrint(
            coreLogger.requestMessage(
                url: url,
                method: method,
                headers: headers,
                body: body
            )
        )
    }

    func logResponseDetails(
        url: URL,
        statusCode: Int,
        headers: [AnyHashable: Any],
        body: Data?
    ) {
        guard isLoggingEnabled else { return }

        debugPrint(
            coreLogger.responseMessage(
                url: url,
                statusCode: statusCode,
                headers: headers,
                body: body
            )
        )
    }

    func logTextPlacementModelDetails(_ model: TextPlacementModel) {
        guard isLoggingEnabled else { return }

        var lines: [String] = []
        lines.append("\n\(dashLineTen) Text Placement Model Details \(dashLineTen)")
        lines.append("Action Type       : \(model.actionType ?? "N/A")")
        lines.append("Action Target     : \(model.actionTarget ?? "N/A")")
        lines.append("Content Text      : \(model.contentText ?? "N/A")")
        lines.append("Action Link       : \(model.actionLink ?? "N/A")")
        lines.append("Action Content ID : \(model.actionContentId ?? "N/A")")
        if let htmlContent = model.htmlContent {
            lines.append("HTML Content      : \(htmlContent)")
        }
        lines.append("\(dashLineFifty)\n")

        let message = lines.joined(separator: "\n")
        debugPrint(message)
    }

    func logPopupPlacementModelDetails(_ model: PopupPlacementModel) {
        guard isLoggingEnabled else { return }

        var lines: [String] = []
        lines.append("\n\(dashLineTen) Popup Placement Model Details \(dashLineTen)")
        lines.append("Overlay Type                  : \(model.overlayType)")
        lines.append("Location                      : \(model.location ?? "")")
        lines.append("Brand Logo URL                : \(model.brandLogoUrl)")
        lines.append("WebView URL                   : \(model.webViewUrl)")
        lines.append("Overlay Title                 : \(model.overlayTitle.string)")
        lines.append("Overlay Subtitle              : \(model.overlaySubtitle.string)")
        lines.append("Overlay Container Bar Heading : \(model.overlayContainerBarHeading.string)")
        lines.append("Body Header                   : \(model.bodyHeader.string)")
        lines.append("Disclosure                    : \(model.disclosure.string)")

        if let primaryActionButton = model.primaryActionButtonAttributes {
            lines.append("\n\(dashLineTen) Primary Action Button Details \(dashLineTen)")
            lines.append("  Data Overlay Type       : \(primaryActionButton.dataOverlayType ?? "N/A")")
            lines.append("  Data Content Fetch      : \(primaryActionButton.dataContentFetch ?? "N/A")")
            lines.append("  Data Action Target      : \(primaryActionButton.dataActionTarget ?? "N/A")")
            lines.append("  Data Action Type        : \(primaryActionButton.dataActionType ?? "N/A")")
            lines.append("  Data Action Content ID  : \(primaryActionButton.dataActionContentId ?? "N/A")")
            lines.append("  Data Location           : \(primaryActionButton.dataLocation ?? "N/A")")
            lines.append("  Button Text             : \(primaryActionButton.buttonText ?? "N/A")")
        } else {
            lines.append("\(dashLineTen) Primary Action Button: N/A \(dashLineTen)")
        }

        if !model.dynamicBodyModel.bodyDiv.isEmpty {
            lines.append("\n\(dashLineTen) Dynamic Body Model Details \(dashLineTen)")
            for (key, bodyContent) in model.dynamicBodyModel.bodyDiv {
                lines.append("  Body Div Key [\(key)]:")
                for (tag, value) in bodyContent.tagValuePairs {
                    lines.append("    - \(tag): \(value)")
                }
            }
            lines.append("\(dashLineFifty)\n")
        } else {
            lines.append("\n\(dashLineTen) Dynamic Body Model Details \(dashLineTen)")
            lines.append("Dynamic Body Model: N/A")
            lines.append("\(dashLineFifty)\n")
        }

        let message = lines.joined(separator: "\n")
        debugPrint(message)
    }

    func logLoadingURL(url: URL) {
        guard isLoggingEnabled else { return }

        debugPrint(coreLogger.loadingURLMessage(url))
    }

    func logReCaptchaToken(token: String) {
        guard isLoggingEnabled else { return }

        debugPrint(coreLogger.reCaptchaTokenMessage(token))
    }

    func logApplicationResultDetails(_ payload: [String: Any]) {
        guard isLoggingEnabled else { return }

        debugPrint(coreLogger.applicationResultMessage(payload))
    }

    func printWebAnchorLogs(data: String) {
        guard isLoggingEnabled else { return }

        debugPrint(coreLogger.webAnchorsMessage(data))
    }

}
