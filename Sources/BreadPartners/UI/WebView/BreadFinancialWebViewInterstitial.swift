//------------------------------------------------------------------------------
//  File:          BreadFinancialWebViewInterstitial.swift
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
import WebKit

protocol AppRestartListener {
    func onAppRestartClicked(url: String)
}

private struct DisclosurePDFCaptureSession {
    let webView: WKWebView
    let contentReadyObserver: DocumentContentReadyObserver
}

private extension UIViewController {
    @objc func dismissSelf() {
        dismiss(animated: true)
    }
}

/// Manages WebView interactions and events within the SDK.
internal class BreadFinancialWebViewInterstitial: NSObject, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate {
    let callback: ((BreadPartnerEvents) -> Void)
    let logger: Logger

    private let navigationConfirmationPresenter: any NavigationConfirmationPresenting
    private let openExternalURL: (URL) -> Void

    @MainActor
    private var disclosureCaptureSession: DisclosurePDFCaptureSession?

    @MainActor
    private lazy var disclosurePDFExportCoordinator = PDFExportCoordinator(
        onFailure: { [weak self] error in
            self?.callback(.sdkError(error: error))
        },
        onFinish: { [weak self] in
            self?.disclosureCaptureSession = nil
        }
    )

    var appRestartListener: AppRestartListener?
    var onPageLoadCompleted: ((Result<URL, Error>) -> Void)?
    /// Stores a pending navigation URL that is waiting for the user to confirm
    /// they want to leave the current page (simulating a beforeunload dialog).
    var pendingNavigationURL: URL?
    /// Set to `true` when a LOG_OUT_OR_RESTART message is received from the web app,
    /// so the navigation confirmation dialog is shown only for that specific flow.
    var pendingLogOutOrRestart = false

    init(
        logger: Logger,
        callback: @escaping (BreadPartnerEvents) -> Void,
        openExternalURL: @escaping (URL) -> Void = { url in
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        },
        navigationConfirmationPresenter: (any NavigationConfirmationPresenting)? = nil
    ) {
        self.logger = logger
        self.callback = callback
        self.openExternalURL = openExternalURL
        self.navigationConfirmationPresenter =
            navigationConfirmationPresenter ?? UIKitNavigationConfirmationPresenter()
    }

    func createWebView(with url: URL) -> WKWebView {
        let contentController = WKUserContentController()
        contentController.add(self, name: "messageHandler")

        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        config.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: config)
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        } else {
            UserDefaults.standard.set(true, forKey: "WebKitDeveloperExtras")
        }

        webView.navigationDelegate = self
        webView.uiDelegate = self

        logger.logLoadingURL(url: url)
        var request = URLRequest(url: url)
        request.setValue(Constants.headerPlatformValue, forHTTPHeaderField: Constants.headerPlatformKey)
        webView.load(request)

        return webView
    }

    func loadPage(for webView: WKWebView) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            onPageLoadCompleted = { result in
                switch result {
                case .success(let url):
                    continuation.resume(returning: url)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Intercepts navigation actions. Shows a native "Leave page?" confirmation
    /// dialog only when a LOG_OUT_OR_RESTART message was previously received from
    /// the web app. All other navigations are allowed through immediately.
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let requestURL = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let isLinkActivated = navigationAction.navigationType == .linkActivated
        let isFormSubmit = navigationAction.navigationType == .formSubmitted

        // Only intercept link/form navigations that follow a LOG_OUT_OR_RESTART message.
        guard (isLinkActivated || isFormSubmit) && pendingLogOutOrRestart else {
            decisionHandler(.allow)
            return
        }

        handleRestartNavigation(
            to: requestURL,
            load: { url in webView.load(URLRequest(url: url)) },
            decisionHandler: decisionHandler
        )
    }

    func handleRestartNavigation(
        to requestURL: URL,
        load: @escaping (URL) -> Void,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        // If this URL was already confirmed by the user, allow it through.
        if let pending = pendingNavigationURL, pending == requestURL {
            pendingNavigationURL = nil
            decisionHandler(.allow)
            return
        }

        // Cancel the navigation and show a native "Leave page?" dialog.
        decisionHandler(.cancel)
        pendingNavigationURL = requestURL

        let didPresent = navigationConfirmationPresenter.presentNavigationConfirmation(
            onLeave: { [weak self] in
                self?.pendingNavigationURL = nil
                self?.pendingLogOutOrRestart = false
                load(requestURL)
            },
            onStay: { [weak self] in
                self?.pendingNavigationURL = nil
                self?.pendingLogOutOrRestart = false
            }
        )

        guard didPresent else {
            // No view controller found — just proceed with navigation.
            pendingNavigationURL = nil
            pendingLogOutOrRestart = false
            load(requestURL)
            return
        }
    }

    func webView(
        _ webView: WKWebView, didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        // Capture and nil out the handler before calling it to prevent the continuation
        // from being resumed more than once if didFail fires multiple times.
        let handler = onPageLoadCompleted
        onPageLoadCompleted = nil
        handler?(.failure(error))
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Inject the anchor tag interception script on every page load
        injectAnchorInterceptorScript(view: webView)

        if let url = webView.url {
            // Capture and nil out the handler before calling it to prevent the continuation
            // from being resumed more than once. This can happen when messages like
            // LOG_OUT_OR_RESTART trigger a new page load, causing didFinish to fire again.
            let handler = onPageLoadCompleted
            onPageLoadCompleted = nil
            handler?(.success(url))
        }
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        handleScriptMessageBody(message.body)
    }

    func handleScriptMessageBody(_ body: Any) {
        if let parsedData = body as? [String: Any],
            let action = parsedData["action"] as? [String: Any],
            let type = action["type"] as? String
        {

            switch type {
            case "LOG_OUT_OR_RESTART":
                // Signal that the next link/form navigation should show a confirmation dialog.
                pendingLogOutOrRestart = true

            case "APP_RESTART":
                if let payload = action["payload"] as? String {
                    onAppRestartClicked(url: "\(payload)")
                } else {
                    logger.printLog("Issue in restarting application")
                }
            case "AnchorTags":
                if let payload = action["payload"] as? [String] {
                    //                    logger.printWebAnchorLogs(data:"\(payload.joined(separator: "\n"))")
                } else {
                    //                    logger.printWebAnchorLogs(data:"Anchor Tags: No anchors found")
                }

            case "OPEN_EXTERNAL":
                if let url = action["payload"] as? String {
                    if let externalURL = URL(string: url) {
                        openExternalURL(externalURL)
                    }
                }
            case "HEIGHT_CHANGED":
                break

            case "LOAD_ADOBE_TRACKING_ID":
                if let payload = action["payload"] as? [String: Any] {
                    if let adobeTrackingId = payload["adobeTrackingId"] {
                        if (logger.isLoggingEnabled) {
                            logger.printLog("BreadPartnersSDK: AdobeTrackingID: \(adobeTrackingId)")
                        }
                    }
                }

            case "VIEW_PAGE":
                if let payload = action["payload"] as? [String: Any],
                    let pageName = payload["pageName"] as? String
                {
                    callback(.screenName(name: pageName))
                }

            case "CANCEL_APPLICATION":
                callback(.popupClosed)

            case "SUBMIT_APPLICATION":
                callback(.screenName(name: "submit-application"))

            case "RECEIVE_APPLICATION_RESULT":
                if let payload = action["payload"] as? [String: Any] {
                    logger.logApplicationResultDetails(payload)
                    callback(.webViewSuccess(result: payload))
                }

            case "RECEIVE_PRESCREEN_APPLICATION_RESULT":
                if let payload = action["payload"] as? [String: Any] {
                    logger.logApplicationResultDetails(payload)
                    callback(.webViewSuccess(result: payload))
                }

            case "UNIFIED_OFFERS_RECEIVED":
                if let payload = action["payload"] as? [String: Any] {
                    logger.logApplicationResultDetails(payload)
                    callback(.webViewSuccess(result: payload))
                    callback(.unifiedOffersReceived(result: payload))
                }

            case "RECEIVE_PREQUAL_APPLICATION_RESULT":
                if let payload = action["payload"] as? [String: Any] {
                    logger.logApplicationResultDetails(payload)
                    callback(.webViewSuccess(result: payload))
                    callback(.receivePrequalApplicationResult(result: payload))
                }

            case "RECEIVE_UNIFIED_CHECKOUT_APPLICATION_RESULT":
                if let payload = action["payload"] as? [String: Any] {
                    logger.logApplicationResultDetails(payload)
                    callback(.webViewSuccess(result: payload))
                    callback(.receiveUnifiedCheckoutApplicationResult(result: payload))
                    callback(.popupClosed)
                }

            case "SUBMIT_PREQUAL_APPLICATION":
                callback(.submitPrequalApplication)

            case "APPLICATION_COMPLETED":
                callback(.screenName(name: "application-completed"))
                callback(.applicationCompleted)
                callback(.popupClosed)

            case "OFFER_RESPONSE":
                if let payload = action["payload"] as? String,
                    let offerResponse = OfferResponse(rawValue: payload)
                {
                    callback(.offerResponse(response: offerResponse))
                    if offerResponse == .no || offerResponse == .notMe {
                        callback(.popupClosed)
                    }
                }

            case "RECEIVE_ACCOUNT_EXISTS":
                if let payload = action["payload"] as? [String: Any] {
                    logger.printLog("BreadPartnersSDK: RECEIVE_ACCOUNT_EXISTS: \(body)")
                    callback(.receiveAccountExist(result: payload))
                }

            default:
                logger.printLog("BreadPartnersSDK: WebViewMessage: \(body)")
            }
        }

    }

    /// Called by WebKit when a page requests a new window (e.g. `window.open()`).
    ///
    /// When the requested URL is `nil` or empty (typical for `about:blank` popups
    /// where the web app writes disclosure HTML into a new window via `document.write()`),
    /// we return a real `WKWebView` so the content can be captured and displayed as a PDF.
    /// All other new-window requests are ignored by returning `nil`.
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        let requestURL = navigationAction.request.url

        // about:blank is used when the page does window.open() and then writes
        // HTML into the new window (e.g. disclosure documents).
        // Return a hosted WKWebView so the content renders in a modal sheet.
        if requestURL == nil || (requestURL?.absoluteString ?? "").isEmpty {
            return makeDisclosureCaptureWebView(with: configuration)
        }

        return nil
    }

    /// Creates an off-screen `WKWebView` for capturing disclosure content that the web app
    /// injects into a new window via `window.open()` + `document.write()`.
    ///
    /// Called from the `WKUIDelegate` new-window callback when the requested URL is empty.
    /// The web view is given a large off-screen frame (800×1200) for a reasonable PDF page
    /// size, and is retained by a capture session until the asynchronous
    /// PDF export completes. A one-shot `DocumentContentReadyObserver` is attached as its
    /// navigation delegate to wait for the HTML to load and then trigger PDF generation.
    ///
    /// - Parameter configuration: The WebKit-supplied config, reused so the popup shares the
    ///   parent's process pool and data store.
    /// - Returns: The capture WebView, or `nil` if another disclosure session is active.
    func makeDisclosureCaptureWebView(with configuration: WKWebViewConfiguration) -> WKWebView? {
        guard disclosureCaptureSession == nil else { return nil }

        // Use a large off-screen frame so the PDF page size is reasonable.
        let offscreenFrame = CGRect(x: 0, y: 0, width: 800, height: 1200)
        let popupWebView = WKWebView(frame: offscreenFrame, configuration: configuration)

        let contentReadyObserver = DocumentContentReadyObserver(webView: popupWebView) { [weak self] webView in
            guard let self else { return }

            await disclosurePDFExportCoordinator.export(from: webView)
        }

        disclosureCaptureSession = DisclosurePDFCaptureSession(
            webView: popupWebView,
            contentReadyObserver: contentReadyObserver
        )
        popupWebView.navigationDelegate = contentReadyObserver

        return popupWebView
    }

    func injectAnchorInterceptorScript(view: WKWebView?) {
        // CSS to remove the default blue tap-highlight and focus outline that
        // WebKit draws around the first focusable element after navigation.
        let cssScript = """
            (function() {
                var style = document.createElement('style');
                style.textContent = '* { -webkit-tap-highlight-color: transparent !important; outline: none !important; }';
                document.head.appendChild(style);
            })();
            """
        view?.evaluateJavaScript(cssScript, completionHandler: nil)

        // JavaScript code to intercept anchor tags and log them
        let script = """
            (function() {
                function isVisible(elem) {
                    return !!(elem.offsetWidth || elem.offsetHeight || elem.getClientRects().length);
                }

                function handleAnchors() {
                    const anchors = document.querySelectorAll('a[target="_blank"], a[data-open-externally="true"]');
                    const anchorsHTML = Array.from(anchors).map(a => a.outerHTML);

                    if (anchorsHTML.length > 0) {
                        window.webkit.messageHandlers.messageHandler.postMessage({
                            action: { type: 'AnchorTags', payload: anchorsHTML }
                        });
                    } else {
                        window.webkit.messageHandlers.messageHandler.postMessage({
                            action: { type: 'AnchorTags', payload: 'No anchors found' }
                        });
                    }

                    anchors.forEach(a => {
                        if (!a.__handled__) {
                            a.__handled__ = true;
                            a.addEventListener('click', function(event) {
                                event.preventDefault();
                                window.webkit.messageHandlers.messageHandler.postMessage({
                                    action: { type: 'OPEN_EXTERNAL', payload: a.href }
                                });
                            });
                        }
                    });
                }

                function handleRestartButton() {
                    const btn = document.querySelector('#appRestart');
                    if (btn && isVisible(btn)) {
                        if (!btn.__handled__) {
                            btn.__handled__ = true;
                            btn.addEventListener('click', function(event) {
                                event.preventDefault();
                                if (btn.href) {
                                    // Send the URL to the native iOS code to trigger the restart
                                    window.webkit.messageHandlers.messageHandler.postMessage({
                                        action: { type: 'APP_RESTART', payload: btn.href }
                                    });
                                }
                            });
                        }
                    }
                }

                // Initial run
                handleAnchors();
                handleRestartButton();

                // MutationObserver to handle dynamically added elements like anchor tags and the restart button
                const observer = new MutationObserver(function(mutations) {
                    mutations.forEach(function(mutation) {
                        if (mutation.addedNodes.length) {
                            handleAnchors();
                            handleRestartButton();
                        }
                    });
                });

                observer.observe(document.body, { childList: true, subtree: true });
            })();
            """

        // Inject the script into the WebView
        view?.evaluateJavaScript(script, completionHandler: nil)
    }

    func onAppRestartClicked(url: String) {
        appRestartListener?.onAppRestartClicked(url: url)
    }

}
