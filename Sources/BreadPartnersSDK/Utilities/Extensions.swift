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
import SwiftDraw

//  Provides reusable extension methods for use across apps integrating the Bread Partners SDK.
public extension UIImageView {
    /// - Parameter targetSize: The size of the box the image will
    ///   ultimately be laid out into (e.g. the fixed height + max width
    ///   used by the caller's Auto Layout constraints). Prefer passing
    ///   this explicitly rather than relying on `bounds.size`: this
    ///   method is typically called immediately after creating the
    ///   `UIImageView`, before it has been added to a layout pass, so
    ///   `bounds` is still `.zero` at that point. Rasterizing an SVG at
    ///   the wrong size gives the resulting `UIImage` an intrinsic
    ///   content size whose aspect ratio doesn't match the view's final
    ///   constrained frame - Auto Layout then sizes the view from that
    ///   mismatched intrinsic size, and `.scaleAspectFit` centers the
    ///   correctly-proportioned artwork inside an oversized box, leaving
    ///   large blank gaps on both sides. Passing the real target box
    ///   size up front keeps the rasterized image's aspect ratio (and
    ///   therefore the view's resolved width) consistent with the final
    ///   layout, so the artwork hugs its frame with no letterboxing.
    func loadImage(
        from url: URL,
        targetSize: CGSize? = nil,
        completion: @escaping @Sendable (Bool) -> Void
    ) {
        let targetSize = targetSize ?? self.bounds.size
        Task {
            guard
                let data = await Task.detached(priority: .userInitiated, operation: {
                    try? Data(contentsOf: url)
                }).value
            else {
                completion(false)
                return
            }

            if Self.isSVG(data: data) {
                let size = targetSize == .zero ? CGSize(width: 200, height: 200) : targetSize
                if let image = Self.renderSVG(data: data, size: size) {
                    self.image = image
                    completion(true)
                } else {
                    completion(false)
                }
                return
            }

            if let image = UIImage(data: data) {
                self.image = image
                completion(true)
            } else {
                completion(false)
            }
        }
    }

    /// Cheap sniff of the first bytes to detect SVG (XML/text) content
    /// vs. a raster format (PNG/JPEG/etc.), which are binary.
    ///
    /// Note: many real-world SVGs (especially Adobe Illustrator exports)
    /// contain a large `<?xml?>` + `<!DOCTYPE svg ... [ <!ENTITY ...> ... ]>`
    /// preamble - sometimes several KB - before the actual `<svg` opening
    /// tag appears. A too-small sniff window will miss the tag entirely
    /// and misclassify the file as non-SVG. We sniff a generous 8 KB
    /// (or the whole file if smaller) to reliably cover this case.
    private static func isSVG(data: Data) -> Bool {
        guard let head = String(data: data.prefix(1024), encoding: .utf8)?.lowercased()
        else { return false }
        return head.contains("<svg")
    }

    /// Parses and rasterizes an SVG directly into a `UIImage` using
    /// SwiftDraw's pure-Swift SVG parser/renderer. Unlike a SwiftUI-based
    /// approach, this requires no SwiftUI hosting controller or
    /// off-screen window - SwiftDraw draws straight into a `CGContext`
    /// via `UIGraphicsImageRenderer`, which is both simpler and safe to
    /// call off the main thread.
    private static func renderSVG(data: Data, size: CGSize) -> UIImage? {
        guard size.width > 0, size.height > 0 else { return nil }
        guard let svg = SVG(data: data) else { return nil }

        // Render into a box that preserves the SVG's own aspect ratio
        // (derived from its viewBox/width/height) instead of stretching
        // it into an arbitrary target box. Forcing a mismatched aspect
        // ratio here would shrink the artwork and pad the rest of the
        // canvas with transparent space, which then gets shrunk again by
        // the UIImageView's `.scaleAspectFit`, making the visible
        // logo/icon look far smaller than intended.
        let renderSize = aspectFitSize(for: svg.size, within: size)
        return svg.rasterize(size: renderSize, scale: UIScreen.main.scale)
    }

    /// Computes the largest size that fits within `boundingSize` while
    /// preserving the SVG's own intrinsic aspect ratio (mirrors "aspect
    /// fit" behavior, but applied to the render canvas itself rather
    /// than after the fact on a padded/stretched bitmap).
    private static func aspectFitSize(for svgSize: CGSize, within boundingSize: CGSize) -> CGSize {
        guard svgSize.width > 0, svgSize.height > 0 else { return boundingSize }

        let ratio = svgSize.width / svgSize.height
        let boundingRatio = boundingSize.width / boundingSize.height
        if ratio > boundingRatio {
            return CGSize(width: boundingSize.width, height: boundingSize.width / ratio)
        } else {
            return CGSize(width: boundingSize.height * ratio, height: boundingSize.height)
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

extension Optional where Wrapped == String {
    func takeIfNotEmpty() -> String? {
        guard let self = self,
            !self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }
        return self
    }
}

extension String {
    /// Converts an HTML string to NSAttributedString with formatting preserved
    func htmlToAttributedString() -> NSAttributedString? {
        guard let data = self.data(using: .utf8) else { return nil }
        
        do {
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            
            return try NSAttributedString(data: data, options: options, documentAttributes: nil)
        } catch {
            return nil
        }
    }
}
