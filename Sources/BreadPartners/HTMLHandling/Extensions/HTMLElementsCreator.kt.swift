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
