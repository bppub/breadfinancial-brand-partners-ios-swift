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
}
