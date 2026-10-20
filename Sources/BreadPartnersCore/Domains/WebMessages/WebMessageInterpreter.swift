//------------------------------------------------------------------------------
//  File:          WebMessageInterpreter.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Foundation

package enum WebMessageDisposition: Sendable, Equatable {
    case interpreted
    case ignored
    case malformed
    case unknown
}

package enum WebMessageAction: Sendable, Equatable {
    case logoutOrRestart
    case restartApplication(url: String)
    case invalidRestartPayload
    case openExternalURL(String)
    case adobeTrackingID(Data)
    case screenName(String)
    case popupClosed
    case submitPrequalApplication
    case logApplicationResult(Data)
    case webViewSuccess(Data)
    case unifiedOffersReceived(Data)
    case receivePrequalApplicationResult(Data)
    case receiveUnifiedCheckoutApplicationResult(Data)
    case applicationCompleted
    case offerResponse(OfferResponse)
    case logAccountExists(Data)
    case receiveAccountExists(Data)
    case unknownMessage(type: String)
}

package struct WebMessageInterpretation: Sendable, Equatable {
    package let disposition: WebMessageDisposition
    package let actions: [WebMessageAction]

    package init(
        disposition: WebMessageDisposition,
        actions: [WebMessageAction] = []
    ) {
        self.disposition = disposition
        self.actions = actions
    }
}

package struct WebMessageInterpreter: Sendable {
    package init() {}

    package func interpret(_ messageBody: Any) -> WebMessageInterpretation {
        guard
            let body = messageBody as? [String: Any],
            let action = body["action"] as? [String: Any],
            let type = action["type"] as? String
        else {
            return WebMessageInterpretation(disposition: .malformed)
        }

        switch type {
        case "LOG_OUT_OR_RESTART":
            return interpreted(.logoutOrRestart)

        case "APP_RESTART":
            guard let url = action["payload"] as? String else {
                return WebMessageInterpretation(
                    disposition: .malformed,
                    actions: [.invalidRestartPayload]
                )
            }
            return interpreted(.restartApplication(url: url))

        case "AnchorTags", "HEIGHT_CHANGED":
            return WebMessageInterpretation(disposition: .ignored)

        case "OPEN_EXTERNAL":
            guard let url = action["payload"] as? String else {
                return WebMessageInterpretation(disposition: .ignored)
            }
            return interpreted(.openExternalURL(url))

        case "LOAD_ADOBE_TRACKING_ID":
            guard
                let payload = action["payload"] as? [String: Any],
                let trackingID = payload["adobeTrackingId"],
                let data = jsonData(for: trackingID)
            else {
                return WebMessageInterpretation(disposition: .ignored)
            }
            return interpreted(.adobeTrackingID(data))

        case "VIEW_PAGE":
            guard
                let payload = action["payload"] as? [String: Any],
                let pageName = payload["pageName"] as? String
            else {
                return WebMessageInterpretation(disposition: .malformed)
            }
            return interpreted(.screenName(pageName))

        case "CANCEL_APPLICATION":
            return interpreted(.popupClosed)

        case "SUBMIT_APPLICATION":
            return interpreted(.screenName("submit-application"))

        case "RECEIVE_APPLICATION_RESULT", "RECEIVE_PRESCREEN_APPLICATION_RESULT":
            guard let payload = payloadData(from: action) else {
                return WebMessageInterpretation(disposition: .malformed)
            }
            return interpreted(.logApplicationResult(payload), .webViewSuccess(payload))

        case "UNIFIED_OFFERS_RECEIVED":
            guard let payload = payloadData(from: action) else {
                return WebMessageInterpretation(disposition: .malformed)
            }
            return interpreted(
                .logApplicationResult(payload),
                .webViewSuccess(payload),
                .unifiedOffersReceived(payload)
            )

        case "RECEIVE_PREQUAL_APPLICATION_RESULT":
            guard let payload = payloadData(from: action) else {
                return WebMessageInterpretation(disposition: .malformed)
            }
            return interpreted(
                .logApplicationResult(payload),
                .webViewSuccess(payload),
                .receivePrequalApplicationResult(payload)
            )

        case "RECEIVE_UNIFIED_CHECKOUT_APPLICATION_RESULT":
            guard let payload = payloadData(from: action) else {
                return WebMessageInterpretation(disposition: .malformed)
            }
            return interpreted(
                .logApplicationResult(payload),
                .webViewSuccess(payload),
                .receiveUnifiedCheckoutApplicationResult(payload),
                .popupClosed
            )

        case "SUBMIT_PREQUAL_APPLICATION":
            return interpreted(.submitPrequalApplication)

        case "APPLICATION_COMPLETED":
            return interpreted(
                .screenName("application-completed"),
                .applicationCompleted,
                .popupClosed
            )

        case "OFFER_RESPONSE":
            guard
                let rawValue = action["payload"] as? String,
                let response = OfferResponse(rawValue: rawValue)
            else {
                return WebMessageInterpretation(disposition: .malformed)
            }
            if response == .no || response == .notMe {
                return interpreted(.offerResponse(response), .popupClosed)
            }
            return interpreted(.offerResponse(response))

        case "RECEIVE_ACCOUNT_EXISTS":
            guard
                let payload = payloadData(from: action),
                let bodyData = jsonData(for: body)
            else {
                return WebMessageInterpretation(disposition: .malformed)
            }
            return interpreted(.logAccountExists(bodyData), .receiveAccountExists(payload))

        default:
            return WebMessageInterpretation(
                disposition: .unknown,
                actions: [.unknownMessage(type: type)]
            )
        }
    }

    private func interpreted(_ actions: WebMessageAction...) -> WebMessageInterpretation {
        WebMessageInterpretation(disposition: .interpreted, actions: actions)
    }

    private func payloadData(from action: [String: Any]) -> Data? {
        guard let payload = action["payload"] as? [String: Any] else { return nil }
        return jsonData(for: payload)
    }

    private func jsonData(for value: Any) -> Data? {
        try? JSONSerialization.data(
            withJSONObject: value,
            options: [.fragmentsAllowed, .sortedKeys]
        )
    }
}
