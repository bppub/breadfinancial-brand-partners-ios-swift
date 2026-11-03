//------------------------------------------------------------------------------
//  File:          PDFExportCoordinator.swift
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

@MainActor
protocol PDFGenerating {
    func generate(from webView: WKWebView) async throws -> Data
}

@MainActor
protocol PDFPresenting {
    func present(pdfURL: URL, onDismiss: @escaping () -> Void) -> Bool
}

@MainActor
final class PDFExportCoordinator {
    enum State: Equatable {
        case idle
        case generating
        case presenting
    }

    private(set) var state = State.idle

    private let fileStore: PDFFileStore
    private let generator: any PDFGenerating
    private let presenter: any PDFPresenting
    private let onFailure: (Error) -> Void
    private let onFinish: () -> Void
    private var activeArtifact: PDFArtifact?

    init(
        fileStore: PDFFileStore = PDFFileStore(),
        generator: any PDFGenerating = WKWebViewPDFGenerator(),
        presenter: any PDFPresenting = QuickLookPDFPresenter(),
        onFailure: @escaping (Error) -> Void,
        onFinish: @escaping () -> Void = {}
    ) {
        self.fileStore = fileStore
        self.generator = generator
        self.presenter = presenter
        self.onFailure = onFailure
        self.onFinish = onFinish
    }

    func export(from webView: WKWebView) async {
        guard state == .idle else { return }
        state = .generating

        do {
            let data = try await generator.generate(from: webView)
            let artifact = try fileStore.write(data)
            activeArtifact = artifact
            state = .presenting

            let didPresent = presenter.present(pdfURL: artifact.url) { [weak self] in
                self?.finish(artifact: artifact)
            }
            if !didPresent {
                finish(artifact: artifact)
            }
        } catch {
            finish()
            onFailure(error)
        }
    }

    private func finish(artifact: PDFArtifact? = nil) {
        if let artifact {
            try? artifact.remove()
        }
        activeArtifact = nil
        state = .idle
        onFinish()
    }
}
