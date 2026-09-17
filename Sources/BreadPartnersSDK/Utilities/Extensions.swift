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
import WebKit

//  Provides reusable extension methods for use across apps integrating the Bread Partners SDK.
public extension UIImageView {

    /// Downloads and displays an image from the given URL.
    ///
    /// Supports both raster images (PNG, JPEG, etc.) and vector **SVG** images.
    /// The format is detected from the URL extension and by sniffing the
    /// downloaded bytes, so SVGs served without a `.svg` extension still work.
    ///
    /// - Parameters:
    ///   - url: The remote image URL.
    ///   - completion: Called on the main actor with `true` on success.
    func loadImage(from url: URL, completion: @escaping @Sendable @MainActor (Bool) -> Void) {
        Task { @MainActor in
            // Perform the network download off the main thread.
            let data = await Task.detached(priority: .userInitiated) { () -> Data? in
                return try? Data(contentsOf: url)
            }.value

            guard let data = data else {
                completion(false)
                return
            }

            let isSVG = url.pathExtension.lowercased() == "svg"
                || Self.dataLooksLikeSVG(data)

            if isSVG {
                self.renderSVG(data: data, completion: completion)
            } else if let image = UIImage(data: data) {
                // PNG / JPEG: unchanged original behavior.
                self.image = image
                completion(true)
            } else {
                completion(false)
            }
        }
    }

    /// Lightweight content sniffing to detect SVG payloads.
    private static func dataLooksLikeSVG(_ data: Data) -> Bool {
        guard
            let prefix = String(data: data.prefix(256), encoding: .utf8)?
                .lowercased()
        else { return false }
        return prefix.contains("<svg") || prefix.contains("<?xml")
    }

    /// Renders SVG data into the image view by rasterizing it with WebKit.
    @MainActor
    private func renderSVG(
        data: Data,
        completion: @escaping @Sendable @MainActor (Bool) -> Void
    ) {
        let renderer = SVGImageRenderer(size: bounds.size)
        // Retain the renderer until it finishes, otherwise it is deallocated
        // before the snapshot completes.
        objc_setAssociatedObject(
            self, &UIImageView.svgRendererKey, renderer,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        renderer.render(data: data) { [weak self] image in
            self?.image = image
            objc_setAssociatedObject(
                self as Any, &UIImageView.svgRendererKey, nil,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            completion(image != nil)
        }
    }

    private static var svgRendererKey: UInt8 = 0
}

/// Rasterizes SVG data into a `UIImage` using WebKit.
///
/// A single `WKWebView` is created once and reused for every SVG. Creating a
/// `WKWebView` is expensive (it spins up a web content process), so reusing a
/// pre-warmed instance removes the multi-second cold start on each logo.
@MainActor
private final class SVGImageRenderer: NSObject, WKNavigationDelegate {

    /// Shared, pre-warmed web view reused across all SVG renders.
    private static let sharedWebView: WKWebView = {
        let webView = WKWebView(
            frame: CGRect(x: 0, y: 0, width: 200, height: 200),
            configuration: WKWebViewConfiguration())
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        // Warm up the web content process ahead of the first real render.
        webView.loadHTMLString("<html></html>", baseURL: nil)
        return webView
    }()

    private var completion: ((UIImage?) -> Void)?
    private let size: CGSize

    init(size: CGSize) {
        // Fall back to a sensible default if the image view isn't laid out yet.
        self.size = size == .zero ? CGSize(width: 200, height: 200) : size
        super.init()
    }

    func render(data: Data, completion: @escaping (UIImage?) -> Void) {
        self.completion = completion

        let webView = SVGImageRenderer.sharedWebView
        webView.frame = CGRect(origin: .zero, size: size)
        webView.navigationDelegate = self

        let svgString = String(data: data, encoding: .utf8) ?? ""
        let html = """
        <html>
        <head>
        <meta name='viewport' content='width=device-width, initial-scale=1'>
        <style>
        * { margin: 0; padding: 0; }
        html, body {
            width: 100%;
            height: 100%;
            background: transparent;
            text-align: left;
        }
        svg {
            height: 100%;
            width: auto;
            max-width: 100%;
            display: inline-block;
            vertical-align: top;
        }
        </style>
        </head>
        <body>\(svgString)</body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Snapshot as soon as the content has loaded — no artificial delay.
        let config = WKSnapshotConfiguration()
        config.rect = CGRect(origin: .zero, size: size)
        webView.takeSnapshot(with: config) { [weak self] image, _ in
            self?.finish(with: image)
        }
    }

    func webView(
        _ webView: WKWebView, didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        finish(with: nil)
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        finish(with: nil)
    }

    private func finish(with image: UIImage?) {
        SVGImageRenderer.sharedWebView.navigationDelegate = nil
        completion?(image)
        completion = nil
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
