//------------------------------------------------------------------------------
//  File:          PopupHTMLAttributedStringTests.swift
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
import UIKit

@testable import BreadPartners

@Suite
struct PopupHTMLAttributedStringTests {
    @Test
    func fallsBackToPlainTextWhenUTF8DataIsUnavailable() {
        let html = "<p>Fallback text</p>"
        let result = PopupHTMLAttributedStringConverter.convert(html: html, data: nil) { _ in
            Issue.record("Parser should not be called when UTF-8 data is unavailable")
            return NSAttributedString(string: "Unexpected result")
        }

        #expect(result.string == html)
    }

    @Test
    func fallsBackToPlainTextWhenHTMLParsingThrows() {
        let html = "<p>Fallback text</p>"
        let failure = NSError(domain: "PopupHTMLParser", code: 1)
        let result = PopupHTMLAttributedStringConverter.convert(
            html: html,
            data: Data(html.utf8)
        ) { _ in
            throw failure
        }

        #expect(result.string == html)
    }
}
