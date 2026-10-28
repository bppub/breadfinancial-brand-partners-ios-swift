//------------------------------------------------------------------------------
//  File:          PDFFileStoreTests.swift
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
import Testing

@testable import BreadPartnersCore

@Suite
struct PDFFileStoreTests {
    @Test
    func writePreservesDataAndCreatesUniquePDFURLs() throws {
        let directoryURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let fileStore = PDFFileStore(directoryURL: directoryURL)
        let firstData = Data("first PDF".utf8)
        let secondData = Data("second PDF".utf8)

        let firstArtifact = try fileStore.write(firstData)
        let secondArtifact = try fileStore.write(secondData)

        #expect(firstArtifact.url.pathExtension == "pdf")
        #expect(secondArtifact.url.pathExtension == "pdf")
        #expect(firstArtifact.url.lastPathComponent.hasPrefix("bread-partners-"))
        #expect(firstArtifact.url != secondArtifact.url)
        #expect(try Data(contentsOf: firstArtifact.url) == firstData)
        #expect(try Data(contentsOf: secondArtifact.url) == secondData)
    }

    @Test
    func removeIsIdempotentAndDoesNotRemoveOtherArtifacts() throws {
        let directoryURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let fileStore = PDFFileStore(directoryURL: directoryURL)
        let artifact = try fileStore.write(Data("PDF".utf8))
        let otherArtifact = try fileStore.write(Data("other PDF".utf8))

        try artifact.remove()
        try artifact.remove()

        #expect(!FileManager.default.fileExists(atPath: artifact.url.path))
        #expect(FileManager.default.fileExists(atPath: otherArtifact.url.path))
    }

    @Test
    func writePropagatesDirectoryCreationFailure() throws {
        let parentURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: parentURL) }
        let fileURL = parentURL.appendingPathComponent("not-a-directory")
        try Data("file".utf8).write(to: fileURL)
        let fileStore = PDFFileStore(directoryURL: fileURL)

        do {
            _ = try fileStore.write(Data("PDF".utf8))
            Issue.record("Expected writing into a file path to fail")
        } catch {
            #expect(FileManager.default.fileExists(atPath: fileURL.path))
        }
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PDFFileStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
