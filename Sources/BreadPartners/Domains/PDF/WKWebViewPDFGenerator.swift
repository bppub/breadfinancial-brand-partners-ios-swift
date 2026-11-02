//------------------------------------------------------------------------------
//  File:          WKWebViewPDFGenerator.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import WebKit

@MainActor
protocol PDFGenerating {
    func generate(from webView: WKWebView) async throws -> Data
}

@MainActor
struct WKWebViewPDFGenerator: PDFGenerating {
    func generate(from webView: WKWebView) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            webView.createPDF(configuration: WKPDFConfiguration()) { result in
                continuation.resume(with: result)
            }
        }
    }
}
