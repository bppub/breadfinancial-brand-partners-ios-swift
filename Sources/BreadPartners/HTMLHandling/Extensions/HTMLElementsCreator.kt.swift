//------------------------------------------------------------------------------
//  File:          HTMLElementsCreator.kt.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

import SwiftSoup
import UIKit

extension Document {
    /// Extracts plain text from the first matching element.
    func textFrom(_ selector: String) -> String {
        return (try? self.select(selector).first()?.text()) ?? ""
    }

    /// Extracts and converts HTML content to an NSAttributedString.
    func htmlFrom(_ selector: String) -> NSAttributedString {
        let htmlContent = (try? self.select(selector).html()) ?? ""
        return htmlContent.toAttributedString()
    }
}

extension String {
    /// Converts an HTML string to an NSAttributedString while preserving formatting.
    func toAttributedString() -> NSAttributedString {
        guard let data = self.data(using: .utf8) else { return NSAttributedString(string: self) }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]

        do {
            return try NSAttributedString(data: data, options: options, documentAttributes: nil)
        } catch {
            print("Error converting HTML: \(error)")
            return NSAttributedString(string: self)
        }
    }
}
