//------------------------------------------------------------------------------
//  File:          WKWebViewNavigationTestHost.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  9 2026 Bread Financial
//------------------------------------------------------------------------------

import Foundation
import SwiftUI
import UIKit
import WebKit

@testable import BreadPartners

@objc(WKWebViewNavigationTestHost)
final class WKWebViewNavigationTestHost: NSObject, UITestHostProviding {
    @MainActor
    static func makeView() -> AnyView {
        AnyView(WKWebViewNavigationTestHostView())
    }
}

@MainActor
private struct WKWebViewNavigationTestHostView: View {
    @StateObject private var model = WKWebViewNavigationTestModel()

    var body: some View {
        VStack(spacing: 16) {
            HostedWKWebView(model: model)
                .frame(maxWidth: .infinity)
                .frame(height: 280)

            Button("Generate PDF") {
                model.generatePDF()
            }
            .accessibilityIdentifier("generate-pdf")

            Button("Load document with content") {
                model.loadDocumentWithContent()
            }
            .accessibilityIdentifier("load-document-with-content")

            Button("Load document with delayed content") {
                model.loadDocumentWithDelayedContent()
            }
            .accessibilityIdentifier("load-document-with-delayed-content")

            Text(model.status)
                .accessibilityIdentifier("webkit-navigation-status")
        }
        .padding()
    }
}

@MainActor
private struct HostedWKWebView: UIViewRepresentable {
    @ObservedObject var model: WKWebViewNavigationTestModel

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        model.attach(webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

@MainActor
private final class WKWebViewNavigationTestModel: ObservableObject {
    @Published private(set) var status = "Ready"

    private weak var webView: WKWebView?
    private var navigationDelegate: WKWebViewNavigationTestDelegate?
    private var documentContentReadyObserver: DocumentContentReadyObserver?

    func attach(_ webView: WKWebView) {
        self.webView = webView
    }

    func generatePDF() {
        guard let webView else {
            status = "WebView unavailable"
            return
        }

        documentContentReadyObserver = nil
        status = "Loading PDF content"
        let delegate = makeNavigationDelegate { [weak self] webView in
            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    let pdfData = try await WKWebViewPDFGenerator().generate(from: webView)
                    self.status =
                        pdfData.starts(with: Data("%PDF".utf8))
                        ? "PDF generated"
                        : "PDF output invalid"
                } catch {
                    self.status = "PDF generation failed: \(error.localizedDescription)"
                }
            }
        }
        navigationDelegate = delegate
        webView.navigationDelegate = delegate
        webView.loadHTMLString("<html><body><p>PDF content</p></body></html>", baseURL: nil)
    }

    func loadDocumentWithContent() {
        loadDocument(html: "<html><body><p>Disclosure</p></body></html>")
    }

    func loadDocumentWithDelayedContent() {
        loadDocument(html: "<html><body></body></html>", withDelayedContent: true)
    }

    private func loadDocument(html: String, withDelayedContent: Bool = false) {
        guard let webView else {
            status = "WebView unavailable"
            return
        }

        status = "Loading document"

        let observer = DocumentContentReadyObserver(webView: webView) { [weak self] _ in
            self?.status = "Document ready"
        }
        documentContentReadyObserver = observer

        let delegate = makeNavigationDelegate { [weak self] webView in
            guard let self else { return }

            observer.webView(webView, didFinish: nil)

            guard withDelayedContent else { return }

            Task { @MainActor [weak self] in
                do {
                    try await Task.sleep(nanoseconds: 300_000_000)
                    _ = try await webView.evaluateJavaScript("document.body.innerHTML = '<p>Disclosure</p>'")
                } catch {
                    self?.status = "JavaScript update failed: \(error.localizedDescription)"
                }
            }
        }
        navigationDelegate = delegate
        webView.navigationDelegate = delegate

        webView.loadHTMLString(html, baseURL: nil)
    }

    private func makeNavigationDelegate(
        onFinish: @escaping @MainActor (WKWebView) -> Void
    ) -> WKWebViewNavigationTestDelegate {
        WKWebViewNavigationTestDelegate(
            onStart: { [weak self] in self?.status = "Navigation started" },
            onFinish: { [weak self] webView in
                self?.status = "Navigation finished"
                onFinish(webView)
            },
            onFailure: { [weak self] error in
                self?.status = "Navigation failed: \(error.localizedDescription)"
            },
            onProcessTermination: { [weak self] in
                self?.status = "Web Content process terminated"
            }
        )
    }
}

@MainActor
private final class WKWebViewNavigationTestDelegate: NSObject, WKNavigationDelegate {
    private let onStart: () -> Void
    private let onFinish: (WKWebView) -> Void
    private let onFailure: (Error) -> Void
    private let onProcessTermination: () -> Void

    init(
        onStart: @escaping () -> Void,
        onFinish: @escaping (WKWebView) -> Void,
        onFailure: @escaping (Error) -> Void,
        onProcessTermination: @escaping () -> Void
    ) {
        self.onStart = onStart
        self.onFinish = onFinish
        self.onFailure = onFailure
        self.onProcessTermination = onProcessTermination
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        onStart()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        onFinish(webView)
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        onFailure(error)
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        onFailure(error)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        onProcessTermination()
    }
}
