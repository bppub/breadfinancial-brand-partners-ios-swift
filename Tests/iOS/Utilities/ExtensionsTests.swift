import Foundation
import Testing
import UIKit
@testable import BreadPartners

@Suite @MainActor
struct ExtensionsTests {
    @Test
    func htmlToAttributedStringPreservesTextAndFormatting() throws {
        let attributedString = try #require(
            "<p>Hello <strong>world</strong></p>".htmlToAttributedString()
        )

        #expect(attributedString.string.contains("Hello world"))

        let boldRange = (attributedString.string as NSString).range(of: "world")
        let font = attributedString.attribute(.font, at: boldRange.location, effectiveRange: nil) as? UIFont
        #expect(font?.fontDescriptor.symbolicTraits.contains(.traitBold) == true)
    }

    @Test
    func applyTextStyleAppliesFontAndTextColor() {
        let label = UILabel()
        let style = PopupTextStyle(
            font: .italicSystemFont(ofSize: 18),
            textColor: .systemBlue
        )

        label.applyTextStyle(style: style)

        #expect(label.font?.pointSize == 18)
        #expect(label.font?.fontDescriptor.symbolicTraits.contains(.traitItalic) == true)
        #expect(label.textColor == .systemBlue)
    }

    @Test
    func applyTextStylePreservesExistingFontWhenStyleFontIsNil() {
        let label = UILabel()
        let existingFont = UIFont.systemFont(ofSize: 16)
        label.font = existingFont
        let style = PopupTextStyle(textColor: .systemRed)

        label.applyTextStyle(style: style)

        #expect(label.font == existingFont)
        #expect(label.textColor == .systemRed)
    }

    @Test
    func loadImageLoadsImageFromLocalURL() async throws {
        let rendererFormat = UIGraphicsImageRendererFormat()
        rendererFormat.scale = 1
        let sourceImage = UIGraphicsImageRenderer(
            size: CGSize(width: 1, height: 1),
            format: rendererFormat
        ).image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        let imageData = try #require(sourceImage.pngData())
        let imageURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        try imageData.write(to: imageURL)
        defer { try? FileManager.default.removeItem(at: imageURL) }

        let imageView = UIImageView()
        let loaded = await withCheckedContinuation { continuation in
            imageView.loadImage(from: imageURL) { success in
                continuation.resume(returning: success)
            }
        }

        #expect(loaded)
        #expect(imageView.image != nil)
        #expect(imageView.image?.size == sourceImage.size)
    }

    @Test
    func loadImageReturnsNilIfNoImageInUrl() async throws {
        let imageURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        defer { try? FileManager.default.removeItem(at: imageURL) }

        let imageView = UIImageView()
        let loaded = await withCheckedContinuation { continuation in
            imageView.loadImage(from: imageURL) { success in
                continuation.resume(returning: !success)
            }
        }

        #expect(loaded)
        #expect(imageView.image == nil)
        #expect(imageView.image?.size == nil)
    }

    private func loadImageFromTempFile(into imageView: UIImageView, data: Data, pathExtension: String) async throws -> Bool {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(pathExtension)
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        return await withCheckedContinuation { continuation in
            imageView.loadImage(from: url) { success in
                continuation.resume(returning: success)
            }
        }
    }

    private let sampleSVG = """
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="10" viewBox="0 0 20 10">
            <rect x="0" y="0" width="20" height="10" fill="#FF0000"/>
        </svg>
        """

    @Test
    func loadImageRendersSVGAtIntrinsicSizeWhenImageViewHasNoBounds() async throws {
        let imageView = UIImageView()

        let loaded = try await loadImageFromTempFile(
            into: imageView, data: Data(sampleSVG.utf8), pathExtension: "svg")

        #expect(loaded)
        #expect(imageView.image?.size == CGSize(width: 20, height: 10))
    }

    @Test
    func loadImageRendersSVGAtImageViewBoundsSize() async throws {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 30))

        let loaded = try await loadImageFromTempFile(
            into: imageView, data: Data(sampleSVG.utf8), pathExtension: "svg")

        #expect(loaded)
        #expect(imageView.image?.size == CGSize(width: 40, height: 30))
    }

    @Test
    func loadImageFailsForSVGWithoutRenderableShapes() async throws {
        let svg = #"<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"></svg>"#
        let imageView = UIImageView()

        let loaded = try await loadImageFromTempFile(
            into: imageView, data: Data(svg.utf8), pathExtension: "svg")

        #expect(!loaded)
        #expect(imageView.image == nil)
    }

    @Test
    func loadImageFailsForNonImageData() async throws {
        let imageView = UIImageView()

        let loaded = try await loadImageFromTempFile(
            into: imageView, data: Data("not an image".utf8), pathExtension: "png")

        #expect(!loaded)
        #expect(imageView.image == nil)
    }

    private func rgba(_ color: UIColor) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }

    @Test
    func colorHexParsesWithHashPrefix() {
        let components = rgba(UIColor(hex: "#FF8000"))

        #expect(components.r == 1.0)
        #expect(abs(components.g - 128.0 / 255.0) < 0.001)
        #expect(components.b == 0.0)
        #expect(components.a == 1.0)
    }

    @Test
    func colorHexParsesWithoutHashAndWithWhitespace() {
        let components = rgba(UIColor(hex: "  0000FF \n"))

        #expect(components.r == 0.0)
        #expect(components.g == 0.0)
        #expect(components.b == 1.0)
    }

    @Test
    func colorHexAppliesCustomAlpha() {
        let components = rgba(UIColor(hex: "#00FF00", alpha: 0.5))

        #expect(components.g == 1.0)
        #expect(components.a == 0.5)
    }

    @Test
    func colorHexFallsBackToBlackForInvalidInput() {
        let components = rgba(UIColor(hex: "zzzzzz"))

        #expect(components.r == 0.0)
        #expect(components.g == 0.0)
        #expect(components.b == 0.0)
        #expect(components.a == 1.0)
    }
}
