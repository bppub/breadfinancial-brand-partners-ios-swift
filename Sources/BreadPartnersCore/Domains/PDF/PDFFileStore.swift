//------------------------------------------------------------------------------
//  File:          PDFFileStore.swift
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

package struct PDFArtifact: Sendable {
    package let url: URL

    package func remove() throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }
}

package struct PDFFileStore: Sendable {
    private let directoryURL: URL

    package init(directoryURL: URL = FileManager.default.temporaryDirectory) {
        self.directoryURL = directoryURL
    }

    package func write(_ data: Data) throws -> PDFArtifact {
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        let url = directoryURL.appendingPathComponent("bread-partners-\(UUID().uuidString).pdf")
        try data.write(to: url, options: .atomic)
        return PDFArtifact(url: url)
    }
}
