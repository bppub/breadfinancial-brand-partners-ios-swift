//------------------------------------------------------------------------------
//  File:          HTMLElementsCreator.kt.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import UIKit

enum PopupHTMLAttributedStringConverter {
    static func convert(
        html: String,
        data: Data?,
        parse: (Data) throws -> NSAttributedString
    ) -> NSAttributedString {
        guard let data else { return NSAttributedString(string: html) }

        do {
            return try parse(data)
        } catch {
            print("Error converting HTML: \(error)")
            return NSAttributedString(string: html)
        }
    }
}

extension String {
    /// Converts an HTML string to an NSAttributedString while preserving formatting.
    func toAttributedString() -> NSAttributedString {
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]

        return PopupHTMLAttributedStringConverter.convert(
            html: self,
            data: data(using: .utf8)
        ) { data in
            try NSAttributedString(data: data, options: options, documentAttributes: nil)
        }
    }
}
