//------------------------------------------------------------------------------
//  File:          WebMessageInterpreterTests.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import BreadPartnersCore
import Foundation
import Testing

@Suite struct WebMessageInterpreterTests {
    private let interpreter = WebMessageInterpreter()

    @Test
    func interpretsNonPayloadMessages() {
        #expect(interpret("LOG_OUT_OR_RESTART") == interpreted(.logoutOrRestart))
        #expect(interpret("CANCEL_APPLICATION") == interpreted(.popupClosed))
        #expect(interpret("SUBMIT_APPLICATION") == interpreted(.screenName("submit-application")))
        #expect(interpret("SUBMIT_PREQUAL_APPLICATION") == interpreted(.submitPrequalApplication))
        #expect(
            interpret("APPLICATION_COMPLETED")
                == interpreted(.screenName("application-completed"), .applicationCompleted, .popupClosed)
        )
        #expect(interpret("HEIGHT_CHANGED").disposition == .ignored)
        #expect(interpret("AnchorTags", payload: ["<a>link</a>"]).disposition == .ignored)
    }

    @Test
    func interpretsRestartExternalAndTrackingMessages() throws {
        #expect(
            interpret("APP_RESTART", payload: "https://example.com/restart")
                == interpreted(.restartApplication(url: "https://example.com/restart"))
        )
        #expect(
            interpret("OPEN_EXTERNAL", payload: "https://example.com")
                == interpreted(.openExternalURL("https://example.com"))
        )

        let trackingData = try jsonData(for: "tracking-id")
        #expect(
            interpret("LOAD_ADOBE_TRACKING_ID", payload: ["adobeTrackingId": "tracking-id"])
                == interpreted(.adobeTrackingID(trackingData))
        )
    }

    @Test
    func interpretsScreenNameAndResultMessages() throws {
        let payload: [String: Any] = ["status": "received", "details": ["count": 2]]
        let payloadData = try jsonData(for: payload)

        #expect(
            interpret("VIEW_PAGE", payload: ["pageName": "checkout"])
                == interpreted(.screenName("checkout"))
        )
        for type in ["RECEIVE_APPLICATION_RESULT", "RECEIVE_PRESCREEN_APPLICATION_RESULT"] {
            #expect(
                interpret(type, payload: payload)
                    == interpreted(.logApplicationResult(payloadData), .webViewSuccess(payloadData))
            )
        }
    }

    @Test
    func preservesOrderedMultiEventResultsAndPayloads() throws {
        let payload: [String: Any] = ["status": "approved", "nested": ["value": 123]]
        let payloadData = try jsonData(for: payload)

        #expect(
            interpret("UNIFIED_OFFERS_RECEIVED", payload: payload)
                == interpreted(
                    .logApplicationResult(payloadData),
                    .webViewSuccess(payloadData),
                    .unifiedOffersReceived(payloadData)
                )
        )
        #expect(
            interpret("RECEIVE_PREQUAL_APPLICATION_RESULT", payload: payload)
                == interpreted(
                    .logApplicationResult(payloadData),
                    .webViewSuccess(payloadData),
                    .receivePrequalApplicationResult(payloadData)
                )
        )
        #expect(
            interpret("RECEIVE_UNIFIED_CHECKOUT_APPLICATION_RESULT", payload: payload)
                == interpreted(
                    .logApplicationResult(payloadData),
                    .webViewSuccess(payloadData),
                    .receiveUnifiedCheckoutApplicationResult(payloadData),
                    .popupClosed
                )
        )
    }

    @Test
    func interpretsEveryOfferResponseAndClosesOnlyForNoAndNotMe() {
        for response in [OfferResponse.yes, .no, .notMe, .abandoned, .prescreenNo] {
            let expected: [WebMessageAction] =
                response == .no || response == .notMe
                ? [.offerResponse(response), .popupClosed]
                : [.offerResponse(response)]
            #expect(interpret("OFFER_RESPONSE", payload: response.rawValue).actions == expected)
        }
    }

    @Test
    func interpretsAccountExistsWithLoggingBeforeEvent() throws {
        let payload: [String: Any] = ["account": "exists"]
        let payloadData = try jsonData(for: payload)
        let bodyData = try jsonData(for: ["action": ["type": "RECEIVE_ACCOUNT_EXISTS", "payload": payload]])

        #expect(
            interpret("RECEIVE_ACCOUNT_EXISTS", payload: payload)
                == interpreted(.logAccountExists(bodyData), .receiveAccountExists(payloadData))
        )
    }

    @Test
    func distinguishesMalformedUnknownAndIgnoredMessages() {
        for body: Any in [NSNull(), "not-an-object", ["action"], ["action": "not-an-object"], [:]] {
            #expect(interpreter.interpret(body) == WebMessageInterpretation(disposition: .malformed))
        }

        #expect(
            interpret("FUTURE_MESSAGE")
                == WebMessageInterpretation(
                    disposition: .unknown,
                    actions: [.unknownMessage(type: "FUTURE_MESSAGE")]
                )
        )
        #expect(interpret("OPEN_EXTERNAL", payload: 42).disposition == .ignored)
        #expect(interpret("AnchorTags", payload: "No anchors found").disposition == .ignored)
    }

    @Test
    func rejectsMalformedPayloadsWithoutEmittingCallbackActions() {
        #expect(
            interpret("APP_RESTART", payload: 42)
                == WebMessageInterpretation(
                    disposition: .malformed,
                    actions: [.invalidRestartPayload]
                )
        )
        #expect(interpret("APP_RESTART").actions == [.invalidRestartPayload])
        #expect(interpret("OPEN_EXTERNAL").disposition == .ignored)
        #expect(interpret("OPEN_EXTERNAL", payload: 42).disposition == .ignored)
        #expect(interpret("LOAD_ADOBE_TRACKING_ID").disposition == .ignored)
        #expect(interpret("LOAD_ADOBE_TRACKING_ID", payload: "bad").disposition == .ignored)
        #expect(interpret("LOAD_ADOBE_TRACKING_ID", payload: [:]).disposition == .ignored)
        #expect(interpret("VIEW_PAGE").disposition == .malformed)
        #expect(interpret("VIEW_PAGE", payload: ["pageName": 42]).disposition == .malformed)

        for type in [
            "RECEIVE_APPLICATION_RESULT",
            "RECEIVE_PRESCREEN_APPLICATION_RESULT",
            "UNIFIED_OFFERS_RECEIVED",
            "RECEIVE_PREQUAL_APPLICATION_RESULT",
            "RECEIVE_UNIFIED_CHECKOUT_APPLICATION_RESULT",
            "RECEIVE_ACCOUNT_EXISTS",
        ] {
            #expect(interpret(type).disposition == .malformed)
            #expect(interpret(type, payload: "bad").disposition == .malformed)
        }

        #expect(interpret("OFFER_RESPONSE").disposition == .malformed)
        #expect(interpret("OFFER_RESPONSE", payload: 42).disposition == .malformed)
        #expect(interpret("OFFER_RESPONSE", payload: "UNKNOWN").disposition == .malformed)
    }

    private func interpret(_ type: String, payload: Any? = nil) -> WebMessageInterpretation {
        var action: [String: Any] = ["type": type]
        if let payload {
            action["payload"] = payload
        }
        return interpreter.interpret(["action": action])
    }

    private func interpreted(_ actions: WebMessageAction...) -> WebMessageInterpretation {
        WebMessageInterpretation(disposition: .interpreted, actions: actions)
    }

    private func jsonData(for value: Any) throws -> Data {
        try JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed, .sortedKeys])
    }
}
