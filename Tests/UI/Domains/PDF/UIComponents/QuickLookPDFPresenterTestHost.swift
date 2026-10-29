//------------------------------------------------------------------------------
//  File:          QuickLookPDFPresenterTestHost.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import SwiftUI
import UIKit
@testable import BreadPartners

@objc(QuickLookPDFPresenterTestHost)
final class QuickLookPDFPresenterTestHost: NSObject, UITestHostProviding {
    @MainActor
    static func makeView() -> AnyView {
        AnyView(QuickLookPDFPresenterTestHostView())
    }
}

private struct QuickLookPDFPresenterTestHostView: View {
    @State private var result = "Ready"
    @State private var presenter: QuickLookPDFPresenter?
    @State private var pdfURL: URL?

    var body: some View {
        VStack(spacing: 16) {
            Button("Show PDF preview") {
                showPDFPreview()
            }
            .accessibilityIdentifier("show-pdf-preview")

            Text(result)
                .accessibilityIdentifier("pdf-preview-result")
        }
        .padding()
    }

    @MainActor
    private func showPDFPreview() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("QuickLookPreview-\(UUID().uuidString).pdf")

        do {
            let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 360, height: 480))
            let data = renderer.pdfData { context in
                context.beginPage()
                "QuickLook PDF presenter test content".draw(
                    at: CGPoint(x: 24, y: 24),
                    withAttributes: [.font: UIFont.systemFont(ofSize: 20)]
                )
            }
            try data.write(to: url, options: .atomic)
        } catch {
            result = "PDF creation failed"
            return
        }

        let previewPresenter = QuickLookPDFPresenter()
        presenter = previewPresenter
        pdfURL = url
        let didPresent = previewPresenter.present(pdfURL: url) {
            result = "PDF preview dismissed"
            if let pdfURL {
                try? FileManager.default.removeItem(at: pdfURL)
            }
            presenter = nil
            pdfURL = nil
        }
        result = didPresent ? "PDF preview presented" : "No presenter"
    }
}
