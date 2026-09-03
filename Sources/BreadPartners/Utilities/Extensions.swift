//------------------------------------------------------------------------------
//  File:          Extensions.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

import UIKit

//  Provides reusable extension methods for use across apps integrating the Bread Partners SDK.
public extension UIImageView {
    func loadImage(from url: URL, completion: @escaping @Sendable (Bool) -> Void) {
        Task {
            let result = await Task.detached(priority: .userInitiated) {
                if let data = try? Data(contentsOf: url),
                    let image = UIImage(data: data)
                {
                    return (image as UIImage?, true)
                }
                return (nil as UIImage?, false)
            }.value

            self.image = result.0
            completion(result.1)
        }
    }
}

public extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        let hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var hexInt: UInt64 = 0

        Scanner(string: hexString).scanHexInt64(&hexInt)

        let red = CGFloat((hexInt >> 16) & 0xFF) / 255.0
        let green = CGFloat((hexInt >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hexInt & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension UILabel {
    func applyTextStyle(style: PopupTextStyle) {
        if let font = style.font {
            self.font = font
        }
        self.textColor = style.textColor
    }
}

extension String {
    /// Converts an HTML string to NSAttributedString with formatting preserved
    func htmlToAttributedString() -> NSAttributedString? {
        guard let data = self.data(using: .utf8) else { return nil }

        do {
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue,
            ]

            return try NSAttributedString(data: data, options: options, documentAttributes: nil)
        } catch {
            return nil
        }
    }
}
