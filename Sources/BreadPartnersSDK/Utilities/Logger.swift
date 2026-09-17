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

    let dashLineFifty = String(repeating: "-", count: 50)
    let dashLineFifteen = String(repeating: "-", count: 15)
    let dashLineTen = String(repeating: "-", count: 10)

    func setLogging(enabled: Bool) {
      self.isLoggingEnabled = enabled
    }
    
    func setCallback(_ newCallback: @escaping (BreadPartnerEvents) -> Void) {
          self.callback = newCallback
      }

    nonisolated public func debugPrint(
        _ items: Any..., separator: String = " ", terminator: String = "\n"
    ) {
        guard isLoggingEnabled else { return }
        let logMessage = items.map { "\($0)" }.joined(separator: separator)
        Swift.print(logMessage, terminator: terminator)
        callback(.onSDKEventLog(logs: logMessage))
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
      
      var lines: [String] = []
      lines.append("\n\(dashLineFifteen) Request Details \(dashLineFifteen)")
      lines.append("URL     : \(url)")
      lines.append("Method  : \(method)")
      
      if let headers = headers {
          let headerLines: [String] = headers
              .compactMap { key, value in
                  guard
                      let keyStr = key as? CustomStringConvertible,
                      let valStr = value as? CustomStringConvertible
                  else { return nil }
                  return "\(keyStr): \(valStr)"
              }
              .sorted()

          lines.append("Headers :")
          for headerLine in headerLines {
              lines.append("  \(headerLine)")
          }
      } else {
        lines.append("Headers : None")
      }
      
      let bodyString: String
      if let body = body,
         let json = try? JSONSerialization.jsonObject(with: body),
         let pretty = try? JSONSerialization.data(
           withJSONObject: json,
           options: .prettyPrinted),
         let str = String(data: pretty, encoding: .utf8)
      {
        bodyString = str
      } else {
        bodyString = "No Body"
      }
      lines.append("Body    : \(bodyString)")
      lines.append("\(dashLineFifty)\n")
      
      let message = lines.joined(separator: "\n")
      
      debugPrint(message)
    }
    
    func logResponseDetails(
        url: URL,
        statusCode: Int,
        headers: [AnyHashable: Any],
        body: Data?
    ) {
        guard isLoggingEnabled else { return }

        var lines: [String] = []
        lines.append("\n\(dashLineFifteen) Response Details \(dashLineFifteen)")
        lines.append("URL         : \(url)")
        lines.append("Status Code : \(statusCode)")

        let headerLines: [String] = headers
            .compactMap { key, value in
                guard
                    let keyStr = key as? CustomStringConvertible,
                    let valStr = value as? CustomStringConvertible
                else { return nil }
                return "\(keyStr): \(valStr)"
            }
            .sorted()

        lines.append("Headers :")
        for headerLine in headerLines {
            lines.append("  \(headerLine)")
        }
        
        let bodyString: String = {
            guard let data = body else { return "No Body" }

            if let jsonObj = try? JSONSerialization.jsonObject(with: data, options: []),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObj, options: .prettyPrinted),
               let pretty = String(data: prettyData, encoding: .utf8) {
                return pretty
            }
            if let str = String(data: data, encoding: .utf8) {
                return str
            }
            return "No Body"
        }()
        lines.append("Body        : \(bodyString)")
        lines.append("\(dashLineFifty)\n")

        let message = lines.joined(separator: "\n")
        debugPrint(message)
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

        var lines: [String] = []
        lines.append("\(dashLineFifteen) WebView URL \(dashLineFifteen)")
        lines.append(url.absoluteString.trimmingCharacters(in: .whitespacesAndNewlines))
        lines.append("\(dashLineFifty)")

        let message = lines.joined(separator: "\n")
        debugPrint(message)
    }

    func logReCaptchaToken(token: String) {
        guard isLoggingEnabled else { return }

        var lines: [String] = []
        lines.append("\(dashLineFifteen) ReCAPTCHA TOKEN \(dashLineFifteen)")
        lines.append(token)
        lines.append("\(dashLineFifty)")

        let message = lines.joined(separator: "\n")
        debugPrint(message)
    }

    func logApplicationResultDetails(_ payload: [String: Any]) {
        guard isLoggingEnabled else { return }

        var lines: [String] = []
        lines.append("\n\(dashLineTen) Application Result Details \(dashLineTen)")
        lines.append("Application ID     : \(payload["applicationId"] ?? "N/A")")
        lines.append("Call ID            : \(payload["callId"] ?? "N/A")")
        lines.append("Card Type          : \(payload["cardType"] ?? "N/A")")
        lines.append("Email Address      : \(payload["emailAddress"] ?? "N/A")")
        lines.append("Message            : \(payload["message"] ?? "N/A")")
        lines.append("Mobile Phone       : \(payload["mobilePhone"] ?? "N/A")")
        lines.append("Result             : \(payload["result"] ?? "N/A")")
        lines.append("Status             : \(payload["status"] ?? "N/A")")
        lines.append("\(dashLineFifty)\n")

        let message = lines.joined(separator: "\n")
        debugPrint(message)
    }

    func printWebAnchorLogs(data: String) {
        guard isLoggingEnabled else { return }

        var lines: [String] = []
        lines.append("\n\(dashLineFifteen) Anchors List \(dashLineFifteen)")
        lines.append(data)
        lines.append("\(dashLineFifty)\n")

        let message = lines.joined(separator: "\n")
        debugPrint(message)
    }

}
