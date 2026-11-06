//------------------------------------------------------------------------------
//  File:          PDFExportCoordinatorTests.swift
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
import WebKit

@testable import BreadPartners

@Suite
@MainActor
struct PDFExportCoordinatorTests {
    @Test
    func duplicateRequestsDuringGenerationAreIgnoredAndArtifactLivesUntilDismissal() async throws {
        let directoryURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let generator = PDFGeneratorSpy(suspend: true)
        let presenter = PDFPresenterSpy()
        let coordinator = makeCoordinator(
            directoryURL: directoryURL,
            generator: generator,
            presenter: presenter
        )
        let webView = WKWebView()
        let exportTask = Task { await coordinator.export(from: webView) }
        await generator.waitUntilStarted()

        #expect(coordinator.state == .generating)
        await coordinator.export(from: webView)
        #expect(generator.callCount == 1)

        generator.complete(Data("test PDF".utf8))
        await exportTask.value

        #expect(coordinator.state == .presenting)
        #expect(presenter.presentCount == 1)
        let pdfURL = try #require(presenter.activePDFURL)
        #expect(FileManager.default.fileExists(atPath: pdfURL.path))

        presenter.dismiss()

        #expect(coordinator.state == .idle)
        #expect(!FileManager.default.fileExists(atPath: pdfURL.path))
    }

    @Test
    func generationFailureResetsStateReportsErrorAndAllowsRetry() async throws {
        let directoryURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let generator = PDFGeneratorSpy(outcomes: [.failure(.generation), .success(Data("PDF".utf8))])
        let presenter = PDFPresenterSpy()
        var failures: [Error] = []
        let coordinator = makeCoordinator(
            directoryURL: directoryURL,
            generator: generator,
            presenter: presenter,
            onFailure: { failures.append($0) }
        )

        await coordinator.export(from: WKWebView())

        #expect(coordinator.state == .idle)
        #expect(failures.count == 1)
        #expect(presenter.presentCount == 0)

        await coordinator.export(from: WKWebView())

        #expect(coordinator.state == .presenting)
        #expect(generator.callCount == 2)
        presenter.dismiss()
        #expect(coordinator.state == .idle)
    }

    @Test
    func writeFailureResetsStateAndReportsError() async throws {
        let parentURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: parentURL) }
        let notDirectoryURL = parentURL.appendingPathComponent("file")
        try Data("file".utf8).write(to: notDirectoryURL)
        let generator = PDFGeneratorSpy(outcomes: [.success(Data("PDF".utf8))])
        let presenter = PDFPresenterSpy()
        var failures: [Error] = []
        let coordinator = PDFExportCoordinator(
            fileStore: PDFFileStore(directoryURL: notDirectoryURL),
            generator: generator,
            presenter: presenter,
            onFailure: { failures.append($0) }
        )

        await coordinator.export(from: WKWebView())

        #expect(coordinator.state == .idle)
        #expect(failures.count == 1)
        #expect(presenter.presentCount == 0)
    }

    @Test
    func unavailablePresenterCleansArtifactAndReturnsToIdleWithoutFailure() async throws {
        let directoryURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let presenter = PDFPresenterSpy(isAvailable: false)
        var failures: [Error] = []
        let coordinator = makeCoordinator(
            directoryURL: directoryURL,
            generator: PDFGeneratorSpy(outcomes: [.success(Data("PDF".utf8))]),
            presenter: presenter,
            onFailure: { failures.append($0) }
        )

        await coordinator.export(from: WKWebView())

        #expect(coordinator.state == .idle)
        #expect(failures.isEmpty)
        #expect(presenter.presentCount == 1)
        #expect(presenter.activePDFURL == nil)
        #expect(try FileManager.default.contentsOfDirectory(atPath: directoryURL.path).isEmpty)
    }

    private func makeCoordinator(
        directoryURL: URL,
        generator: PDFGeneratorSpy,
        presenter: PDFPresenterSpy,
        onFailure: @escaping (Error) -> Void = { _ in }
    ) -> PDFExportCoordinator {
        PDFExportCoordinator(
            fileStore: PDFFileStore(directoryURL: directoryURL),
            generator: generator,
            presenter: presenter,
            onFailure: onFailure
        )
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PDFExportCoordinatorTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

@MainActor
private final class PDFGeneratorSpy: PDFGenerating {
    private enum Outcome {
        case success(Data)
        case failure(StubError)
    }

    private(set) var callCount = 0
    private var outcomes: [Outcome]
    private var pendingContinuation: CheckedContinuation<Data, Error>?
    private var startedContinuation: CheckedContinuation<Void, Never>?
    private let suspend: Bool

    init(suspend: Bool = false) {
        self.suspend = suspend
        outcomes = [.success(Data("PDF".utf8))]
    }

    init(outcomes: [Result<Data, StubError>]) {
        suspend = false
        self.outcomes = outcomes.map { result in
            switch result {
            case .success(let data): .success(data)
            case .failure(let error): .failure(error)
            }
        }
    }

    func generate(from webView: WKWebView) async throws -> Data {
        callCount += 1
        if suspend {
            return try await withCheckedThrowingContinuation { continuation in
                pendingContinuation = continuation
                startedContinuation?.resume()
                startedContinuation = nil
            }
        }

        switch outcomes.removeFirst() {
        case .success(let data): return data
        case .failure(let error): throw error
        }
    }

    func waitUntilStarted() async {
        guard callCount == 0 else { return }
        await withCheckedContinuation { continuation in
            startedContinuation = continuation
        }
    }

    func complete(_ data: Data) {
        pendingContinuation?.resume(returning: data)
        pendingContinuation = nil
    }
}

@MainActor
private final class PDFPresenterSpy: PDFPresenting {
    private(set) var presentCount = 0
    private(set) var activePDFURL: URL?
    private var onDismiss: (() -> Void)?
    private let isAvailable: Bool

    init(isAvailable: Bool = true) {
        self.isAvailable = isAvailable
    }

    func present(pdfURL: URL, onDismiss: @escaping () -> Void) -> Bool {
        presentCount += 1
        guard isAvailable else { return false }
        activePDFURL = pdfURL
        self.onDismiss = onDismiss
        return true
    }

    func dismiss() {
        let dismissal = onDismiss
        onDismiss = nil
        activePDFURL = nil
        dismissal?()
    }
}

private enum StubError: Error {
    case generation
}
