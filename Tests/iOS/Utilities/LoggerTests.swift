import Foundation
import Testing
@testable import BreadPartners

@Suite struct LoggerTests {
    private final class EventBox: @unchecked Sendable {
        var events: [BreadPartnerEvents] = []
    }

    @Test
    func disabledLoggerDoesNotEmitEvent() {
        let box = EventBox()
        let logger = Logger()
        logger.setCallback { box.events.append($0) }

        logger.debugPrint("hidden")

        #expect(box.events.isEmpty)
    }

    @Test
    func enabledLoggerEmitsJoinedMessage() {
        let box = EventBox()
        let logger = Logger()
        logger.setLogging(enabled: true)
        logger.setCallback { box.events.append($0) }

        logger.debugPrint("value", 42, separator: " | ")

        #expect(box.events.count == 1)
        guard case let .onSDKEventLog(logs)? = box.events.first else {
            Issue.record("Expected an SDK log event")
            return
        }
        #expect(logs == "value | 42")
    }

    @Test
    func requestLoggingEmitsOneFormattedEvent() throws {
        let box = EventBox()
        let logger = Logger()
        logger.setLogging(enabled: true)
        logger.setCallback { box.events.append($0) }
        let url = try #require(URL(string: "https://example.com/request"))

        logger.logRequestDetails(
            url: url,
            method: "POST",
            headers: ["X-Test": "value"],
            body: Data(#"{"id":1}"#.utf8)
        )

        #expect(box.events.count == 1)
        guard case let .onSDKEventLog(logs)? = box.events.first else {
            Issue.record("Expected an SDK log event")
            return
        }
        #expect(logs.contains("Request Details"))
        #expect(logs.contains("X-Test: value"))
        #expect(logs.contains("\"id\" : 1"))
    }

    @Test
    func replacingCallbackStopsUsingPreviousCallback() {
        let logger = Logger()
        let firstBox = EventBox()
        let secondBox = EventBox()
        logger.setLogging(enabled: true)

        logger.setCallback { firstBox.events.append($0) }
        logger.debugPrint("one")

        logger.setCallback { secondBox.events.append($0) }
        logger.debugPrint("two")

        #expect(firstBox.events.count == 1)
        #expect(secondBox.events.count == 1)
    }

    @Test
    func printLogRespectsLoggingFlag() {
        let box = EventBox()
        let logger = Logger()
        logger.setCallback { box.events.append($0) }

        logger.printLog("hidden")
        #expect(box.events.isEmpty)

        logger.setLogging(enabled: true)
        logger.printLog("visible")
        #expect(box.events.count == 1)
    }

    @Test
    func requestLoggingUsesNoBodyWhenBodyIsNil() throws {
        let box = EventBox()
        let logger = Logger()
        logger.setLogging(enabled: true)
        logger.setCallback { box.events.append($0) }
        let url = try #require(URL(string: "https://example.com/request"))

        logger.logRequestDetails(url: url, method: "GET", headers: nil, body: nil)

        guard case let .onSDKEventLog(logs)? = box.events.first else {
            Issue.record("Expected an SDK log event")
            return
        }
        #expect(logs.contains("Method  : GET"))
        #expect(logs.contains("Body    : No Body"))
    }

    @Test
    func responseLoggingIncludesStatusUrlAndBody() throws {
        let box = EventBox()
        let logger = Logger()
        logger.setLogging(enabled: true)
        logger.setCallback { box.events.append($0) }
        let url = try #require(URL(string: "https://example.com/response"))

        logger.logResponseDetails(
            url: url,
            statusCode: 201,
            headers: ["X-Result": "ok"],
            body: Data(#"{"ok":true}"#.utf8)
        )

        guard case let .onSDKEventLog(logs)? = box.events.first else {
            Issue.record("Expected an SDK log event")
            return
        }
        #expect(logs.contains("Response Details"))
        #expect(logs.contains("Status Code : 201"))
        #expect(logs.contains("https://example.com/response"))
        #expect(logs.contains("\"ok\""))
    }

    @Test
    func textPlacementLoggingIncludesModelFields() {
        let box = EventBox()
        let logger = Logger()
        logger.setLogging(enabled: true)
        logger.setCallback { box.events.append($0) }
        let model = TextPlacementModel(
            actionType: "SHOW_OVERLAY",
            actionTarget: "modal",
            contentText: "Pay over time",
            actionLink: "Learn More",
            actionContentId: "cid-1",
            htmlContent: "<div>Pay over time</div>"
        )

        logger.logTextPlacementModelDetails(model)

        guard case let .onSDKEventLog(logs)? = box.events.first else {
            Issue.record("Expected an SDK log event")
            return
        }
        #expect(logs.contains("Text Placement Model Details"))
        #expect(logs.contains("SHOW_OVERLAY"))
        #expect(logs.contains("Pay over time"))
        #expect(logs.contains("cid-1"))
    }

    @Test
    func textPlacementLoggingUsesNAForMissingFields() {
        let box = EventBox()
        let logger = Logger()
        logger.setLogging(enabled: true)
        logger.setCallback { box.events.append($0) }
        let model = TextPlacementModel(
            actionType: nil,
            actionTarget: nil,
            contentText: nil,
            actionLink: nil,
            actionContentId: nil,
            htmlContent: nil
        )

        logger.logTextPlacementModelDetails(model)

        guard case let .onSDKEventLog(logs)? = box.events.first else {
            Issue.record("Expected an SDK log event")
            return
        }
        #expect(logs.contains("Action Type       : N/A"))
        #expect(logs.contains("Action Target     : N/A"))
        #expect(logs.contains("Content Text      : N/A"))
        #expect(logs.contains("Action Link       : N/A"))
        #expect(logs.contains("Action Content ID : N/A"))
        #expect(!logs.contains("HTML Content      :"))
    }

    @Test
    func popupPlacementLoggingIncludesPrimaryActionAndDynamicBody() {
        let box = EventBox()
        let logger = Logger()
        logger.setLogging(enabled: true)
        logger.setCallback { box.events.append($0) }
        let model = PopupPlacementModel(
            overlayType: "EMBEDDED_OVERLAY",
            location: "checkout",
            brandLogoUrl: "https://example.com/logo.png",
            webViewUrl: "https://example.com/embed",
            overlayTitle: NSAttributedString(string: "Title"),
            overlaySubtitle: NSAttributedString(string: "Subtitle"),
            overlayContainerBarHeading: NSAttributedString(string: "Heading"),
            bodyHeader: NSAttributedString(string: "Header"),
            primaryActionButtonAttributes: PrimaryActionButtonModel(
                dataActionType: "SHOW_OVERLAY",
                buttonText: "Continue"
            ),
            dynamicBodyModel: PopupPlacementModel.DynamicBodyModel(
                bodyDiv: [
                    "div0": PopupPlacementModel.DynamicBodyContent(
                        tagValuePairs: ["p": "Details"]
                    )
                ]
            ),
            disclosure: NSAttributedString(string: "Disclosure"),
            disclosureHTML: "<p>Disclosure</p>"
        )

        logger.logPopupPlacementModelDetails(model)

        guard case let .onSDKEventLog(logs)? = box.events.first else {
            Issue.record("Expected an SDK log event")
            return
        }
        #expect(logs.contains("Popup Placement Model Details"))
        #expect(logs.contains("Primary Action Button Details"))
        #expect(logs.contains("Data Overlay Type       : N/A"))
        #expect(logs.contains("Data Content Fetch      : N/A"))
        #expect(logs.contains("Data Action Target      : N/A"))
        #expect(logs.contains("Data Action Content ID  : N/A"))
        #expect(logs.contains("Data Location           : N/A"))
        #expect(logs.contains("Continue"))
        #expect(logs.contains("Dynamic Body Model Details"))
    }

    @Test
    func popupPlacementLoggingHandlesEmptyDynamicBody() {
        let box = EventBox()
        let logger = Logger()
        logger.setLogging(enabled: true)
        logger.setCallback { box.events.append($0) }
        let model = PopupPlacementModel(
            overlayType: "EMBEDDED_OVERLAY",
            location: nil,
            brandLogoUrl: "",
            webViewUrl: "",
            overlayTitle: NSAttributedString(string: ""),
            overlaySubtitle: NSAttributedString(string: ""),
            overlayContainerBarHeading: NSAttributedString(string: ""),
            bodyHeader: NSAttributedString(string: ""),
            primaryActionButtonAttributes: nil,
            dynamicBodyModel: PopupPlacementModel.DynamicBodyModel(bodyDiv: [:]),
            disclosure: NSAttributedString(string: ""),
            disclosureHTML: ""
        )

        logger.logPopupPlacementModelDetails(model)

        guard case let .onSDKEventLog(logs)? = box.events.first else {
            Issue.record("Expected an SDK log event")
            return
        }
        #expect(logs.contains("Primary Action Button: N/A"))
        #expect(logs.contains("Dynamic Body Model: N/A"))
    }

    @Test
    func popupPlacementLoggingUsesNAForMissingActionTypeAndButtonText() {
        let box = EventBox()
        let logger = Logger()
        logger.setLogging(enabled: true)
        logger.setCallback { box.events.append($0) }
        let model = PopupPlacementModel(
            overlayType: "EMBEDDED_OVERLAY",
            location: nil,
            brandLogoUrl: "",
            webViewUrl: "",
            overlayTitle: NSAttributedString(string: ""),
            overlaySubtitle: NSAttributedString(string: ""),
            overlayContainerBarHeading: NSAttributedString(string: ""),
            bodyHeader: NSAttributedString(string: ""),
            primaryActionButtonAttributes: PrimaryActionButtonModel(
                dataActionType: nil,
                buttonText: nil
            ),
            dynamicBodyModel: PopupPlacementModel.DynamicBodyModel(bodyDiv: [:]),
            disclosure: NSAttributedString(string: ""),
            disclosureHTML: ""
        )

        logger.logPopupPlacementModelDetails(model)

        guard case let .onSDKEventLog(logs)? = box.events.first else {
            Issue.record("Expected an SDK log event")
            return
        }
        #expect(logs.contains("Data Action Type        : N/A"))
        #expect(logs.contains("Button Text             : N/A"))
    }

    @Test
    func loadingURLLoggingEmitsURL() throws {
        let box = EventBox()
        let logger = Logger()
        logger.setLogging(enabled: true)
        logger.setCallback { box.events.append($0) }
        let url = try #require(URL(string: "https://example.com/loading"))

        logger.logLoadingURL(url: url)

        guard case let .onSDKEventLog(logs)? = box.events.first else {
            Issue.record("Expected an SDK log event")
            return
        }
        #expect(logs.contains("WebView URL"))
        #expect(logs.contains(url.absoluteString))
    }

    @Test
    func recaptchaTokenLoggingEmitsToken() {
        let box = EventBox()
        let logger = Logger()
        logger.setLogging(enabled: true)
        logger.setCallback { box.events.append($0) }

        logger.logReCaptchaToken(token: "token-123")

        guard case let .onSDKEventLog(logs)? = box.events.first else {
            Issue.record("Expected an SDK log event")
            return
        }
        #expect(logs.contains("ReCAPTCHA TOKEN"))
        #expect(logs.contains("token-123"))
    }

    @Test
    func applicationResultLoggingEmitsPayloadFields() {
        let box = EventBox()
        let logger = Logger()
        logger.setLogging(enabled: true)
        logger.setCallback { box.events.append($0) }

        logger.logApplicationResultDetails([
            "applicationId": "app-1",
            "status": "approved",
        ])

        guard case let .onSDKEventLog(logs)? = box.events.first else {
            Issue.record("Expected an SDK log event")
            return
        }
        #expect(logs.contains("Application Result Details"))
        #expect(logs.contains("Application ID     : app-1"))
        #expect(logs.contains("Status             : approved"))
        #expect(logs.contains("Message            : N/A"))
    }

    @Test
    func applicationResultLoggingUsesNAForMissingFields() {
        let box = EventBox()
        let logger = Logger()
        logger.setLogging(enabled: true)
        logger.setCallback { box.events.append($0) }

        logger.logApplicationResultDetails([:])

        guard case let .onSDKEventLog(logs)? = box.events.first else {
            Issue.record("Expected an SDK log event")
            return
        }
        #expect(logs.contains("Application ID     : N/A"))
        #expect(logs.contains("Call ID            : N/A"))
        #expect(logs.contains("Card Type          : N/A"))
        #expect(logs.contains("Email Address      : N/A"))
        #expect(logs.contains("Message            : N/A"))
        #expect(logs.contains("Mobile Phone       : N/A"))
        #expect(logs.contains("Result             : N/A"))
        #expect(logs.contains("Status             : N/A"))
    }

    @Test
    func webAnchorLoggingEmitsAnchorData() {
        let box = EventBox()
        let logger = Logger()
        logger.setLogging(enabled: true)
        logger.setCallback { box.events.append($0) }

        logger.printWebAnchorLogs(data: "Anchor Tags: <a href=\"/help\">")

        guard case let .onSDKEventLog(logs)? = box.events.first else {
            Issue.record("Expected an SDK log event")
            return
        }
        #expect(logs.contains("Anchors List"))
        #expect(logs.contains("Anchor Tags: <a href=\"/help\">"))
    }

    @Test
    func loggerMethodsDoNotEmitWhenDisabled() throws {
        let box = EventBox()
        let logger = Logger()
        logger.setCallback { box.events.append($0) }
        let url = try #require(URL(string: "https://example.com/disabled"))

        logger.printLog("hidden")
        logger.logRequestDetails(url: url, method: "GET", headers: nil, body: nil)
        logger.logResponseDetails(url: url, statusCode: 500, headers: [:], body: nil)
        logger.logTextPlacementModelDetails(
            TextPlacementModel(
                actionType: nil,
                actionTarget: nil,
                contentText: nil,
                actionLink: nil,
                actionContentId: nil,
                htmlContent: nil
            )
        )
        logger.logPopupPlacementModelDetails(
            PopupPlacementModel(
                overlayType: "EMBEDDED_OVERLAY",
                location: nil,
                brandLogoUrl: "",
                webViewUrl: "",
                overlayTitle: NSAttributedString(string: ""),
                overlaySubtitle: NSAttributedString(string: ""),
                overlayContainerBarHeading: NSAttributedString(string: ""),
                bodyHeader: NSAttributedString(string: ""),
                primaryActionButtonAttributes: nil,
                dynamicBodyModel: PopupPlacementModel.DynamicBodyModel(bodyDiv: [:]),
                disclosure: NSAttributedString(string: ""),
                disclosureHTML: ""
            )
        )
        logger.logLoadingURL(url: url)
        logger.logReCaptchaToken(token: "hidden-token")
        logger.logApplicationResultDetails(["applicationId": "hidden-app"])
        logger.printWebAnchorLogs(data: "hidden-anchors")

        #expect(box.events.isEmpty)
    }
}
