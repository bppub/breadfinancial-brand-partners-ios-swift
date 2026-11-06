//------------------------------------------------------------------------------
//  File:          SVGImageRendererTests.swift
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

@Suite @MainActor
struct SVGImageRendererTests {

    // MARK: - Helpers

    private struct Pixel {
        let r: Int
        let g: Int
        let b: Int
        let a: Int
    }

    private func svg(
        _ body: String,
        attributes: String = ##"width="20" height="20" viewBox="0 0 20 20""##
    ) -> Data {
        Data(#"<svg xmlns="http://www.w3.org/2000/svg" \#(attributes)>\#(body)</svg>"#.utf8)
    }

    private func render(_ data: Data, targetSize: CGSize = .zero) -> UIImage? {
        SVGImageRenderer.image(from: data, targetSize: targetSize)
    }

    /// Reads the RGBA pixel at the given point (in points, origin top-left).
    private func pixel(in image: UIImage, x: CGFloat, y: CGFloat) throws -> Pixel {
        let cgImage = try #require(image.cgImage)
        let width = cgImage.width
        let height = cgImage.height
        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        let context = try #require(
            CGContext(
                data: &buffer,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let px = min(max(Int(x * image.scale), 0), width - 1)
        let py = min(max(Int(y * image.scale), 0), height - 1)
        let offset = (py * width + px) * 4
        return Pixel(
            r: Int(buffer[offset]),
            g: Int(buffer[offset + 1]),
            b: Int(buffer[offset + 2]),
            a: Int(buffer[offset + 3])
        )
    }

    private func expectColor(
        _ pixel: Pixel,
        r: Int, g: Int, b: Int, a: Int = 255,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(abs(pixel.r - r) <= 2, "red \(pixel.r) != \(r)", sourceLocation: sourceLocation)
        #expect(abs(pixel.g - g) <= 2, "green \(pixel.g) != \(g)", sourceLocation: sourceLocation)
        #expect(abs(pixel.b - b) <= 2, "blue \(pixel.b) != \(b)", sourceLocation: sourceLocation)
        #expect(abs(pixel.a - a) <= 2, "alpha \(pixel.a) != \(a)", sourceLocation: sourceLocation)
    }

    // MARK: - isSVG

    @Test
    func isSVGDetectsSVGMarkup() {
        #expect(SVGImageRenderer.isSVG(data: Data("<svg></svg>".utf8)))
        #expect(SVGImageRenderer.isSVG(data: Data("<?xml version=\"1.0\"?><SVG></SVG>".utf8)))
    }

    @Test
    func isSVGRejectsNonSVGData() {
        #expect(!SVGImageRenderer.isSVG(data: Data("<html></html>".utf8)))
        #expect(!SVGImageRenderer.isSVG(data: Data()))
        #expect(!SVGImageRenderer.isSVG(data: Data([0xFF, 0xFE, 0x00, 0x80])))
    }

    // MARK: - Failure cases

    @Test
    func imageReturnsNilForNonSVGData() {
        #expect(render(Data("hello".utf8)) == nil)
    }

    @Test
    func imageReturnsNilForMalformedXML() {
        let data = Data(##"<svg width="10" height="10"><rect width="10" height="10"></svg>"##.utf8)
        #expect(render(data) == nil)
    }

    @Test
    func imageReturnsNilWhenThereAreNoShapes() {
        #expect(render(svg("")) == nil)
    }

    @Test
    func imageReturnsNilForShapesWithMissingRequiredAttributes() {
        let body = ##"<rect width="10"/><circle cx="5" cy="5"/><line x1="0" y1="0"/><polygon points="1,2"/>"##
        #expect(render(svg(body)) == nil)
    }

    @Test
    func imageIgnoresShapesInsideNonRenderingElements() {
        let body = ##"<defs><clipPath id="c"><rect width="20" height="20"/></clipPath></defs>"##
        #expect(render(svg(body)) == nil)
    }

    @Test
    func imageStillRendersVisibleShapesNextToDefinitions() throws {
        let body = """
            <defs><rect width="20" height="20" fill="#0000FF"/></defs>
            <rect width="10" height="20" fill="#FF0000"/>
            """
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 5, y: 10), r: 255, g: 0, b: 0)
        expectColor(try pixel(in: image, x: 15, y: 10), r: 0, g: 0, b: 0, a: 0)
    }

    // MARK: - Sizing

    @Test
    func imageUsesViewBoxForIntrinsicSize() throws {
        let data = svg(
            ##"<rect width="5" height="5"/>"##,
            attributes: ##"width="100" height="100" viewBox="0 0 30 15""##
        )
        let image = try #require(render(data))

        #expect(image.size == CGSize(width: 30, height: 15))
    }

    @Test
    func imageUsesWidthAndHeightWhenViewBoxIsMissing() throws {
        let data = svg(##"<rect width="5" height="5"/>"##, attributes: ##"width="40px" height="25px""##)
        let image = try #require(render(data))

        #expect(image.size == CGSize(width: 40, height: 25))
    }

    @Test
    func imageFallsBackToDefaultSizeWithoutAnySizeInformation() throws {
        let image = try #require(render(svg(##"<rect width="5" height="5"/>"##, attributes: "")))

        #expect(image.size == CGSize(width: 200, height: 200))
    }

    @Test
    func imageIgnoresPercentageWidthAndHeight() throws {
        let data = svg(##"<rect width="5" height="5"/>"##, attributes: ##"width="100%" height="100%""##)
        let image = try #require(render(data))

        #expect(image.size == CGSize(width: 200, height: 200))
    }

    @Test
    func imageUsesTargetSizeAndScalesContent() throws {
        let data = svg(##"<rect width="10" height="20" fill="#FF0000"/>"##)
        let image = try #require(render(data, targetSize: CGSize(width: 40, height: 40)))

        #expect(image.size == CGSize(width: 40, height: 40))
        // Left half is filled after scaling 2x, right half is empty.
        expectColor(try pixel(in: image, x: 15, y: 20), r: 255, g: 0, b: 0)
        expectColor(try pixel(in: image, x: 30, y: 20), r: 0, g: 0, b: 0, a: 0)
    }

    @Test
    func imageUsesIntrinsicSizeWhenTargetSizeHasZeroDimension() throws {
        let data = svg(##"<rect width="10" height="10"/>"##)

        let zeroWidth = try #require(render(data, targetSize: CGSize(width: 0, height: 50)))
        let zeroHeight = try #require(render(data, targetSize: CGSize(width: 50, height: 0)))

        #expect(zeroWidth.size == CGSize(width: 20, height: 20))
        #expect(zeroHeight.size == CGSize(width: 20, height: 20))
    }

    @Test
    func imageHonorsViewBoxOrigin() throws {
        let data = svg(
            ##"<rect x="10" y="10" width="10" height="10" fill="#00FF00"/>"##,
            attributes: ##"viewBox="10 10 10 10""##
        )
        let image = try #require(render(data))

        #expect(image.size == CGSize(width: 10, height: 10))
        expectColor(try pixel(in: image, x: 5, y: 5), r: 0, g: 255, b: 0)
    }

    @Test
    func imageReturnsNilWhenViewBoxHasZeroWidthOrHeight() {
        let shape = ##"<rect width="5" height="5" fill="#FF0000"/>"##

        #expect(render(svg(shape, attributes: ##"viewBox="0 0 0 10""##)) == nil)
        #expect(render(svg(shape, attributes: ##"viewBox="0 0 10 0""##)) == nil)
    }

    @Test
    func imageReturnsNilWhenViewBoxHasNegativeSize() {
        let shape = ##"<rect width="5" height="5" fill="#FF0000"/>"##

        #expect(render(svg(shape, attributes: ##"viewBox="0 0 -10 10""##)) == nil)
    }

    @Test
    func imageReturnsNilWhenWidthAndHeightAreZero() {
        let shape = ##"<rect width="5" height="5" fill="#FF0000"/>"##

        #expect(render(svg(shape, attributes: ##"width="0" height="0""##)) == nil)
        #expect(render(svg(shape, attributes: ##"width="10" height="0""##)) == nil)
    }

    @Test
    func imageReturnsNilForZeroIntrinsicSizeEvenWithTargetSize() {
        let shape = ##"<rect width="5" height="5" fill="#FF0000"/>"##
        let data = svg(shape, attributes: ##"viewBox="0 0 0 0""##)

        #expect(render(data, targetSize: CGSize(width: 40, height: 40)) == nil)
    }

    // MARK: - Shapes

    @Test
    func imageRendersRectWithDefaultBlackFill() throws {
        let image = try #require(render(svg(##"<rect width="20" height="20"/>"##)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 0, g: 0, b: 0)
    }

    @Test
    func imageRendersRoundedRect() throws {
        let image = try #require(
            render(svg(##"<rect width="20" height="20" rx="10" fill="#FF0000"/>"##)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
        expectColor(try pixel(in: image, x: 0.5, y: 0.5), r: 0, g: 0, b: 0, a: 0)
    }

    @Test
    func imageRendersCircle() throws {
        let image = try #require(
            render(svg(##"<circle cx="10" cy="10" r="8" fill="#FF0000"/>"##)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
        expectColor(try pixel(in: image, x: 1, y: 1), r: 0, g: 0, b: 0, a: 0)
    }

    @Test
    func imageRendersEllipse() throws {
        let image = try #require(
            render(svg(##"<ellipse cx="10" cy="10" rx="9" ry="4" fill="#FF0000"/>"##)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
        expectColor(try pixel(in: image, x: 10, y: 2), r: 0, g: 0, b: 0, a: 0)
    }

    @Test
    func imageRendersPolygon() throws {
        let image = try #require(
            render(svg(##"<polygon points="0,0 20,0 0,20" fill="#FF0000"/>"##)))

        expectColor(try pixel(in: image, x: 3, y: 3), r: 255, g: 0, b: 0)
        expectColor(try pixel(in: image, x: 17, y: 17), r: 0, g: 0, b: 0, a: 0)
    }

    @Test
    func imageRendersStrokedLine() throws {
        let body = ##"<line x1="0" y1="10" x2="20" y2="10" stroke="#0000FF" stroke-width="4"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 0, g: 0, b: 255)
        expectColor(try pixel(in: image, x: 10, y: 2), r: 0, g: 0, b: 0, a: 0)
    }

    @Test
    func imageRendersAbsolutePathData() throws {
        let image = try #require(
            render(svg(##"<path d="M0 0 H20 V20 H0 Z" fill="#FF0000"/>"##)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
    }

    @Test
    func imageRendersRelativePathData() throws {
        let image = try #require(
            render(svg(##"<path d="m5 5 h10 v10 h-10 z" fill="#FF0000"/>"##)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
        expectColor(try pixel(in: image, x: 2, y: 2), r: 0, g: 0, b: 0, a: 0)
    }

    @Test
    func imageRendersCurvesAndArcsInPathData() throws {
        let body = """
            <path d="M0 20 C0 0 20 0 20 20 Z" fill="#FF0000"/>
            <path d="M2 2 A4 4 0 0 1 10 2 Z" fill="#00FF00"/>
            """
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 17), r: 255, g: 0, b: 0)
    }

    @Test
    func imageReturnsNilForPathWithoutData() {
        #expect(render(svg(##"<path fill="#FF0000"/>"##)) == nil)
    }

    // MARK: - Styling

    @Test
    func imageSupportsFillNone() throws {
        let image = try #require(
            render(svg(##"<rect width="20" height="20" fill="none"/>"##)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 0, g: 0, b: 0, a: 0)
    }

    @Test
    func imageRendersStrokeOnly() throws {
        let body = ##"<rect x="2" y="2" width="16" height="16" fill="none" stroke="#0000FF" stroke-width="4"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 2, y: 10), r: 0, g: 0, b: 255)
        expectColor(try pixel(in: image, x: 10, y: 10), r: 0, g: 0, b: 0, a: 0)
    }

    @Test
    func imageSupportsShortHexColors() throws {
        let image = try #require(render(svg(##"<rect width="20" height="20" fill="#f00"/>"##)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
    }

    @Test
    func imageSupportsEightDigitHexColorsWithAlpha() throws {
        let image = try #require(render(svg(##"<rect width="20" height="20" fill="#FF000080"/>"##)))

        let result = try pixel(in: image, x: 10, y: 10)
        #expect(abs(result.a - 128) <= 2)
    }

    @Test
    func imageSupportsRGBFunctionColors() throws {
        let body = """
            <rect width="10" height="20" fill="rgb(0, 0, 255)"/>
            <rect x="10" width="10" height="20" fill="rgb(100%, 0%, 0%)"/>
            """
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 5, y: 10), r: 0, g: 0, b: 255)
        expectColor(try pixel(in: image, x: 15, y: 10), r: 255, g: 0, b: 0)
    }

    @Test
    func imageSupportsNamedColors() throws {
        let image = try #require(render(svg(##"<rect width="20" height="20" fill="white"/>"##)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 255, b: 255)
    }

    @Test
    func imageSupportsBlackNamedColor() throws {
        let body = ##"<rect width="20" height="20" fill="black"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 0, g: 0, b: 0)
    }

    @Test
    func imageSupportsTransparentNamedColor() throws {
        let body = """
            <rect width="20" height="20" fill="#0000FF"/>
            <rect width="20" height="20" fill="transparent"/>
            """
        let image = try #require(render(svg(body)))

        // A transparent fill draws nothing, so the blue rect underneath stays visible.
        expectColor(try pixel(in: image, x: 10, y: 10), r: 0, g: 0, b: 255)
    }

    @Test
    func imageTreatsNamedColorsAsCaseInsensitiveAndTrimmed() throws {
        let body = """
            <rect width="10" height="20" fill="WHITE"/>
            <rect x="10" width="10" height="20" fill="  White  "/>
            """
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 5, y: 10), r: 255, g: 255, b: 255)
        expectColor(try pixel(in: image, x: 15, y: 10), r: 255, g: 255, b: 255)
    }

    @Test
    func imageSupportsNamedColorsForStroke() throws {
        let body = ##"<rect x="2" y="2" width="16" height="16" fill="none" stroke="white" stroke-width="4"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 2, y: 10), r: 255, g: 255, b: 255)
        expectColor(try pixel(in: image, x: 10, y: 10), r: 0, g: 0, b: 0, a: 0)
    }

    @Test
    func imageSupportsNamedColorsInInlineStyle() throws {
        let body = ##"<rect width="20" height="20" style="fill:white"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 255, b: 255)
    }

    @Test
    func imageIgnoresUnsupportedNamedColors() throws {
        // Only black, white and transparent are supported; other names keep the inherited fill.
        let body = ##"<g fill="#00FF00"><rect width="20" height="20" fill="red"/></g>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 0, g: 255, b: 0)
    }

    @Test
    func imageAppliesOpacity() throws {
        let body = ##"<rect width="20" height="20" fill="#FF0000" opacity="0.5"/>"##
        let image = try #require(render(svg(body)))

        let result = try pixel(in: image, x: 10, y: 10)
        #expect(abs(result.a - 128) <= 2)
    }

    @Test
    func imageMultipliesNestedGroupOpacity() throws {
        let body = ##"<g opacity="0.5"><rect width="20" height="20" fill="#FF0000" opacity="0.5"/></g>"##
        let image = try #require(render(svg(body)))

        let result = try pixel(in: image, x: 10, y: 10)
        #expect(abs(result.a - 64) <= 2)
    }

    @Test
    func imageSkipsShapesWithZeroOpacity() {
        let body = ##"<rect width="20" height="20" fill="#FF0000" opacity="0"/>"##
        let image = render(svg(body))

        if let image {
            #expect((try? pixel(in: image, x: 10, y: 10).a) == 0)
        }
    }

    @Test
    func imageAppliesFillOpacity() throws {
        let body = ##"<rect width="20" height="20" fill="#FF0000" fill-opacity="0.5"/>"##
        let image = try #require(render(svg(body)))

        let result = try pixel(in: image, x: 10, y: 10)
        #expect(abs(result.a - 128) <= 2)
    }

    @Test
    func imageAppliesStrokeWidth() throws {
        let body = ##"<line x1="0" y1="10" x2="20" y2="10" stroke="#0000FF" stroke-width="10"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 6), r: 0, g: 0, b: 255)
        expectColor(try pixel(in: image, x: 10, y: 1), r: 0, g: 0, b: 0, a: 0)
    }

    @Test
    func imageSupportsEvenOddFillRule() throws {
        let path = "M0 0 H20 V20 H0 Z M5 5 H15 V15 H5 Z"
        let evenOdd = try #require(
            render(svg(##"<path d="\##(path)" fill="#FF0000" fill-rule="evenodd"/>"##)))
        let winding = try #require(
            render(svg(##"<path d="\##(path)" fill="#FF0000"/>"##)))

        // Same-direction inner square: even-odd leaves a hole, non-zero winding fills it.
        expectColor(try pixel(in: evenOdd, x: 10, y: 10), r: 0, g: 0, b: 0, a: 0)
        expectColor(try pixel(in: winding, x: 10, y: 10), r: 255, g: 0, b: 0)
    }

    @Test
    func imageKeepsInheritedFillForCurrentColor() throws {
        let body = ##"<g fill="#00FF00"><rect width="20" height="20" fill="currentColor"/></g>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 0, g: 255, b: 0)
    }

    // MARK: - Style sheets

    @Test
    func imageAppliesClassSelectorStyles() throws {
        let body = """
            <style type="text/css">.st0{fill:#FF0000;}</style>
            <rect class="st0" width="20" height="20"/>
            """
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
    }

    @Test
    func imageAppliesCommaSeparatedAndMultipleClasses() throws {
        let body = """
            <style>.a, .b { fill: #0000FF; } .c { stroke: none }</style>
            <rect class="b c" width="10" height="20"/>
            <rect class="a" x="10" width="10" height="20"/>
            """
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 5, y: 10), r: 0, g: 0, b: 255)
        expectColor(try pixel(in: image, x: 15, y: 10), r: 0, g: 0, b: 255)
    }

    @Test
    func imageLetsDirectAttributesOverrideClassStyles() throws {
        let body = """
            <style>.st0{fill:#FF0000;}</style>
            <rect class="st0" fill="#00FF00" width="20" height="20"/>
            """
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 0, g: 255, b: 0)
    }

    @Test
    func imageIgnoresUnsupportedSelectors() throws {
        let body = """
            <style>rect { fill: #FF0000; } #id { fill: #FF0000; }</style>
            <rect width="20" height="20"/>
            """
        let image = try #require(render(svg(body)))

        // Only class selectors are supported, so the default black fill is used.
        expectColor(try pixel(in: image, x: 10, y: 10), r: 0, g: 0, b: 0)
    }

    // MARK: - Transforms

    @Test
    func imageAppliesTranslateTransform() throws {
        let body = ##"<rect width="10" height="10" fill="#FF0000" transform="translate(10, 10)"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 15, y: 15), r: 255, g: 0, b: 0)
        expectColor(try pixel(in: image, x: 5, y: 5), r: 0, g: 0, b: 0, a: 0)
    }

    @Test
    func imageAppliesScaleTransform() throws {
        let body = ##"<rect width="5" height="5" fill="#FF0000" transform="scale(4)"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 18, y: 18), r: 255, g: 0, b: 0)
    }

    @Test
    func imageAppliesRotateTransformAroundCenter() throws {
        let body = ##"<rect width="20" height="6" y="7" fill="#FF0000" transform="rotate(90 10 10)"/>"##
        let image = try #require(render(svg(body)))

        // A horizontal bar rotated 90° around the center becomes vertical.
        expectColor(try pixel(in: image, x: 10, y: 2), r: 255, g: 0, b: 0)
        expectColor(try pixel(in: image, x: 2, y: 10), r: 0, g: 0, b: 0, a: 0)
    }

    @Test
    func imageAppliesMatrixTransform() throws {
        let body = ##"<rect width="10" height="10" fill="#FF0000" transform="matrix(1 0 0 1 10 10)"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 15, y: 15), r: 255, g: 0, b: 0)
    }

    @Test
    func imageAccumulatesNestedGroupTransforms() throws {
        let body = """
            <g transform="translate(5, 0)"><g transform="translate(5, 0)">
                <rect width="10" height="20" fill="#FF0000"/>
            </g></g>
            """
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 15, y: 10), r: 255, g: 0, b: 0)
        expectColor(try pixel(in: image, x: 5, y: 10), r: 0, g: 0, b: 0, a: 0)
    }

    // MARK: - Path data commands

    @Test
    func imageTreatsExtraCoordinatePairsAfterMoveToAsLineTo() throws {
        let image = try #require(
            render(svg(##"<path d="M0 0 20 0 20 20 0 20 Z" fill="#FF0000"/>"##)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
    }

    @Test
    func imageSupportsRepeatedRelativeLineToCoordinates() throws {
        let image = try #require(
            render(svg(##"<path d="M0 0 l20 0 0 20 -20 0 z" fill="#FF0000"/>"##)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
    }

    @Test
    func imageSupportsSmoothCubicCurves() throws {
        let image = try #require(
            render(svg(##"<path d="M0 20 C0 10 5 0 10 0 S20 10 20 20 Z" fill="#FF0000"/>"##)))

        expectColor(try pixel(in: image, x: 10, y: 15), r: 255, g: 0, b: 0)
        expectColor(try pixel(in: image, x: 1, y: 1), r: 0, g: 0, b: 0, a: 0)
    }

    @Test
    func imageSupportsRelativeSmoothCubicCurves() throws {
        let image = try #require(
            render(svg(##"<path d="m0 20 c0 -10 5 -20 10 -20 s10 10 10 20 z" fill="#FF0000"/>"##)))

        expectColor(try pixel(in: image, x: 10, y: 15), r: 255, g: 0, b: 0)
    }

    @Test
    func imageSupportsQuadraticCurves() throws {
        let image = try #require(
            render(svg(##"<path d="M0 20 Q10 0 20 20 Z" fill="#FF0000"/>"##)))

        expectColor(try pixel(in: image, x: 10, y: 15), r: 255, g: 0, b: 0)
        expectColor(try pixel(in: image, x: 10, y: 3), r: 0, g: 0, b: 0, a: 0)
    }

    @Test
    func imageSupportsSmoothQuadraticCurves() throws {
        // The second segment reuses the reflected control point, so it dips below the chord.
        let image = try #require(
            render(svg(##"<path d="M0 10 Q5 0 10 10 T20 10 Z" fill="#FF0000"/>"##)))

        expectColor(try pixel(in: image, x: 5, y: 7), r: 255, g: 0, b: 0)
        expectColor(try pixel(in: image, x: 15, y: 12), r: 255, g: 0, b: 0)
    }

    @Test
    func imageDrawsArcWithZeroRadiusAsStraightLine() throws {
        let image = try #require(
            render(svg(##"<path d="M2 2 A0 0 0 0 1 18 2 L18 18 L2 18 Z" fill="#FF0000"/>"##)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
    }

    @Test
    func imageScalesUpArcRadiiThatAreTooSmall() throws {
        // Radii of 2 can't span 20 units, so they are scaled up to a semicircle.
        let image = try #require(
            render(svg(##"<path d="M0 10 A2 2 0 0 1 20 10 Z" fill="#FF0000"/>"##)))

        expectColor(try pixel(in: image, x: 10, y: 5), r: 255, g: 0, b: 0)
        expectColor(try pixel(in: image, x: 10, y: 15), r: 0, g: 0, b: 0, a: 0)
    }

    @Test
    func imageParsesDecimalAndExponentNumbersInPathData() throws {
        let image = try #require(
            render(svg(##"<path d="M0 0 H20.0 V2e1 H0 Z" fill="#FF0000"/>"##)))
        let signedExponent = try #require(
            render(svg(##"<path d="M0 0 H2E+1 V2e+1 H0 Z" fill="#00FF00"/>"##)))

        expectColor(try pixel(in: image, x: 18, y: 18), r: 255, g: 0, b: 0)
        expectColor(try pixel(in: signedExponent, x: 18, y: 18), r: 0, g: 255, b: 0)
    }

    @Test
    func imageKeepsPathDrawnBeforeUnknownCommand() throws {
        let image = try #require(
            render(svg(##"<path d="M0 0 H20 V20 H0 Z X5 5" fill="#FF0000"/>"##)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
    }

    // MARK: - More transforms

    @Test
    func imageAppliesRotateTransformAroundOrigin() throws {
        let body = ##"<rect width="20" height="10" fill="#FF0000" transform="translate(20 0) rotate(90)"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 15, y: 10), r: 255, g: 0, b: 0)
        expectColor(try pixel(in: image, x: 5, y: 10), r: 0, g: 0, b: 0, a: 0)
    }

    @Test
    func imageAppliesSkewXTransform() throws {
        let body = ##"<rect width="10" height="10" fill="#FF0000" transform="skewX(45)"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 15, y: 9), r: 255, g: 0, b: 0)
        expectColor(try pixel(in: image, x: 3, y: 9), r: 0, g: 0, b: 0, a: 0)
    }

    @Test
    func imageAppliesSkewYTransform() throws {
        let body = ##"<rect width="10" height="10" fill="#FF0000" transform="skewY(45)"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 8, y: 12), r: 255, g: 0, b: 0)
        expectColor(try pixel(in: image, x: 8, y: 2), r: 0, g: 0, b: 0, a: 0)
    }

    @Test
    func imageIgnoresUnknownAndMalformedTransformFunctions() throws {
        let body = ##"<rect width="20" height="20" fill="#FF0000" transform="foo(1) matrix(1 2 3)"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
    }

    @Test
    func imageCombinesMultipleTransformFunctionsSeparatedBySpaces() throws {
        let body = ##"<rect width="5" height="5" fill="#FF0000" transform="translate(10 10)   scale(2)"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 15, y: 15), r: 255, g: 0, b: 0)
        expectColor(try pixel(in: image, x: 5, y: 5), r: 0, g: 0, b: 0, a: 0)
    }

    // MARK: - More colors and styles

    @Test
    func imageAppliesOpacityFromInlineStyle() throws {
        let body = ##"<rect width="20" height="20" style="fill:#FF0000;opacity:0.5"/>"##
        let image = try #require(render(svg(body)))

        let result = try pixel(in: image, x: 10, y: 10)
        #expect(abs(result.a - 128) <= 2)
    }

    @Test
    func imageSupportsRGBAFunctionColors() throws {
        let body = ##"<rect width="20" height="20" fill="rgba(255, 0, 0, 0.5)"/>"##
        let image = try #require(render(svg(body)))

        let result = try pixel(in: image, x: 10, y: 10)
        #expect(abs(result.a - 128) <= 2)
        #expect(result.r > 0)
    }

    @Test
    func imageKeepsInheritedFillForMalformedColors() throws {
        let body = ##"""
            <g fill="#00FF00">
                <rect width="10" height="20" fill="rgb(255, 0, 0"/>
                <rect x="10" width="10" height="20" fill="rgb(255, 0)"/>
            </g>
            """##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 5, y: 10), r: 0, g: 255, b: 0)
        expectColor(try pixel(in: image, x: 15, y: 10), r: 0, g: 255, b: 0)
    }

    @Test
    func imageKeepsInheritedFillForHexColorsWithInvalidLength() throws {
        let body = ##"<g fill="#00FF00"><rect width="20" height="20" fill="#12345"/></g>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 0, g: 255, b: 0)
    }

    // MARK: - Remaining branch coverage

    @Test
    func imageUsesWindingFillRuleForNonzeroValue() throws {
        let body = ##"<path fill="#FF0000" fill-rule="nonzero" d="M0 0H20V20H0Z M5 5H15V15H5Z"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
    }

    @Test
    func imageIgnoresMalformedInlineStyleDeclarations() throws {
        let body = ##"<rect width="20" height="20" style="garbage;fill;fill:#FF0000"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
    }

    @Test
    func imageAppliesInlineStyleStrokeAndIgnoresUnknownProperties() throws {
        let body = ##"""
            <rect width="20" height="20" fill="none" stroke-width="6"
                style="stroke:#00FF00;stroke-linecap:round"/>
            """##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 1, y: 10), r: 0, g: 255, b: 0)
    }

    @Test
    func imageKeepsAttributesWhenClassIsNotInStyleSheet() throws {
        let body = ##"""
            <style>.a { fill: #FF0000 }</style>
            <rect class="unknown" width="20" height="20" fill="#00FF00"/>
            """##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 0, g: 255, b: 0)
    }

    @Test
    func imageLetsLaterClassOverrideEarlierClassProperty() throws {
        let body = ##"""
            <style>.a { fill: #FF0000 } .b { fill: #0000FF }</style>
            <rect class="a b" width="20" height="20"/>
            """##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 0, g: 0, b: 255)
    }

    @Test
    func imageIgnoresStyleSheetDeclarationsWithoutColon() throws {
        let body = ##"""
            <style>.a { garbage; fill: #FF0000 }</style>
            <rect class="a" width="20" height="20"/>
            """##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
    }

    @Test
    func imageSkipsEllipseWithMissingRadius() throws {
        let body = ##"""
            <rect width="20" height="20" fill="#00FF00"/>
            <ellipse cx="10" cy="10" rx="5" fill="#FF0000"/>
            """##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 0, g: 255, b: 0)
    }

    @Test
    func imageSkipsPolygonWithoutPoints() throws {
        let body = ##"""
            <rect width="20" height="20" fill="#00FF00"/>
            <polygon fill="#FF0000"/>
            """##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 0, g: 255, b: 0)
    }

    @Test
    func imageStopsPathParsingWhenMoveHasNoCoordinates() throws {
        let body = ##"""
            <rect width="20" height="20" fill="#00FF00"/>
            <path fill="#FF0000" d="M"/>
            """##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 0, g: 255, b: 0)
    }

    @Test
    func imageSupportsRelativeMoveWithImplicitRelativeLines() throws {
        let body = ##"<path fill="#FF0000" d="m0 0 20 0 0 20 -20 0z"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
    }

    @Test
    func imageSupportsRelativeMoveCommand() throws {
        let body = ##"<path fill="#FF0000" d="m2 2 h16 v16 h-16 z"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
    }

    @Test
    func imageSupportsSmoothCubicWithAndWithoutPreviousControlPoint() throws {
        let withoutPrevious = ##"<path fill="#FF0000" d="M0 0 S20 0 20 20 L0 20Z"/>"##
        let withPrevious = ##"<path fill="#FF0000" d="M0 0 C0 0 20 0 20 10 S20 20 20 20 L0 20Z"/>"##

        let first = try #require(render(svg(withoutPrevious)))
        let second = try #require(render(svg(withPrevious)))

        expectColor(try pixel(in: first, x: 5, y: 18), r: 255, g: 0, b: 0)
        expectColor(try pixel(in: second, x: 5, y: 18), r: 255, g: 0, b: 0)
    }

    @Test
    func imageSupportsSmoothQuadraticWithAndWithoutPreviousControlPoint() throws {
        let withoutPrevious = ##"<path fill="#FF0000" d="M0 0 T20 0 L20 20 L0 20Z"/>"##
        let withPrevious = ##"<path fill="#FF0000" d="M0 0 Q10 0 20 0 T20 20 L0 20Z"/>"##

        let first = try #require(render(svg(withoutPrevious)))
        let second = try #require(render(svg(withPrevious)))

        expectColor(try pixel(in: first, x: 10, y: 10), r: 255, g: 0, b: 0)
        expectColor(try pixel(in: second, x: 5, y: 18), r: 255, g: 0, b: 0)
    }

    @Test
    func imageSupportsRelativeQuadraticCurves() throws {
        let body = ##"<path fill="#FF0000" d="M0 0 q10 0 20 0 q0 10 0 20 l-20 0 z"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
    }

    // MARK: - Coverage: path parsing edge cases

    @Test(arguments: [
        ##"M0 0 L20 0 L20 20 L0 20 Z #"##,
        ##"M0 0 L20 0 L20 20 L0 20 Z 5 5"##,
        ##"M0 0 L20 0 L20 20 L0 20 L5"##,
    ])
    func imageStopsParsingAtMalformedTrailingTokenInsteadOfHanging(pathData: String) throws {
        let body = ##"<path fill="#FF0000" d="\##(pathData)"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
    }

    @Test
    func imageSupportsRelativeSmoothCubic() throws {
        let body = ##"<path fill="#FF0000" d="M0 0 c0 0 20 0 20 10 s0 10 -20 10 z"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
    }

    @Test
    func imageSupportsRelativeSmoothQuadratic() throws {
        let body = ##"<path fill="#FF0000" d="M0 0 L20 0 q0 10 0 20 t-20 0 z"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
    }

    @Test(arguments: [0, 1], [0, 1])
    func imageSupportsAllArcFlagCombinations(largeArc: Int, sweep: Int) throws {
        let forward = ##"<path fill="#FF0000" d="M0 0 A12 12 0 \##(largeArc) \##(sweep) 20 20 L0 20 Z"/>"##
        let backward = ##"<path fill="#FF0000" d="M20 20 A12 12 30 \##(largeArc) \##(sweep) 0 0 L0 20 Z"/>"##
        let wide = ##"<path fill="#FF0000" d="M2 10 A8 4 0 \##(largeArc) \##(sweep) 18 10 Z"/>"##

        for body in [forward, backward, wide] {
            let image = try #require(render(svg(body)))
            #expect(image.size == CGSize(width: 20, height: 20))
        }
    }

    @Test
    func imageDrawsStraightLineForArcWithZeroYRadius() throws {
        let body = ##"<path fill="#FF0000" d="M0 0 A5 0 0 0 1 20 0 L20 20 L0 20 Z"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
    }

    @Test
    func imageDrawsStraightLineForArcWithIdenticalEndpoints() throws {
        let body = ##"<path fill="#FF0000" d="M0 0 A5 5 0 0 1 0 0 L20 0 L20 20 L0 20 Z"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
    }

    @Test
    func imageIgnoresArcMissingFlags() throws {
        let rect = "M0 0 L20 0 L20 20 L0 20 Z"
        let missingFlags = ##"<path fill="#FF0000" d="\##(rect) M2 2 A5 5 0"/>"##
        let invalidFlag = ##"<path fill="#FF0000" d="\##(rect) M2 2 A5 5 0 2 0 10 10"/>"##

        for body in [missingFlags, invalidFlag] {
            let image = try #require(render(svg(body)))
            expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
        }
    }

    // MARK: - Coverage: transform edge cases

    @Test
    func imageTranslatesXOnlyWhenSingleArgumentIsGiven() throws {
        let body = ##"<rect width="5" height="20" fill="#FF0000" transform="translate(10)"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 12, y: 10), r: 255, g: 0, b: 0)
        expectColor(try pixel(in: image, x: 2, y: 10), r: 0, g: 0, b: 0, a: 0)
    }

    @Test
    func imageScalesUniformlyWhenSingleArgumentIsGiven() throws {
        let body = ##"<rect width="5" height="5" fill="#FF0000" transform="scale(2)"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 8, y: 8), r: 255, g: 0, b: 0)
        expectColor(try pixel(in: image, x: 12, y: 12), r: 0, g: 0, b: 0, a: 0)
    }

    @Test(arguments: [
        "translate()", "scale()", "rotate()", "skewX()", "skewY()",
        "5", "(5)", "translate", "translate 5",
    ])
    func imageTreatsTransformsWithoutUsableArgumentsAsIdentity(transform: String) throws {
        let body = ##"<rect width="20" height="20" fill="#FF0000" transform="\##(transform)"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
    }

    // MARK: - Coverage: colour edge cases

    @Test
    func imageFallsBackWhenHexColorHasInvalidDigits() throws {
        let body = ##"<rect width="20" height="20" fill="#GGGGGG"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 0, g: 0, b: 0)
    }

    @Test
    func imageTreatsNonNumericRGBComponentsAsZero() throws {
        let body = ##"<rect width="20" height="20" fill="rgb(abc, 0, 0)"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 0, g: 0, b: 0)
    }

    @Test
    func imageSupportsPercentageRGBComponents() throws {
        let body = ##"<rect width="20" height="20" fill="rgb(100%, 0%, 0%)"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
    }

    @Test
    func imageTreatsNonNumericRGBAAlphaAsOpaque() throws {
        let body = ##"<rect width="20" height="20" fill="rgba(255, 0, 0, abc)"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
    }

    // MARK: - Coverage: stylesheet edge cases

    @Test
    func imageRejectsDataThatIsNotValidUTF8() {
        let data = Data([0x3C, 0x73, 0x76, 0x67, 0xFF, 0xFE, 0x3E])

        #expect(render(data) == nil)
    }

    @Test
    func imageIgnoresStylesheetTextWithoutBraces() throws {
        let body = ##"""
            <style>.a{fill:#FF0000;} garbage-without-braces</style>
            <rect class="a" width="20" height="20"/>
            """##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
    }

    @Test
    func imageIgnoresStylesheetRulesWithoutDeclarations() throws {
        let body = ##"""
            <style>.empty{} .junk{garbage} .a{fill:#FF0000;}</style>
            <rect class="a empty junk" width="20" height="20"/>
            """##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 255, g: 0, b: 0)
    }

    @Test
    func imageLetsLaterStylesheetRuleOverrideEarlierRuleForSameClass() throws {
        let body = ##"""
            <style>.a{fill:#FF0000;} .a{fill:#0000FF;}</style>
            <rect class="a" width="20" height="20"/>
            """##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 10, y: 10), r: 0, g: 0, b: 255)
    }

    // MARK: - Coverage: remaining branches

    @Test
    func imageSupportsRelativeArc() throws {
        let body = ##"<path fill="#FF0000" d="M0 0 a12 12 0 0 1 20 20 L0 20 Z"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 5, y: 15), r: 255, g: 0, b: 0)
    }

    @Test(arguments: [0, 1], [0, 30, 90])
    func imageSupportsSemicircleArcsWithUndersizedRadii(sweep: Int, rotation: Int) throws {
        let bodies = [
            ##"<path fill="#FF0000" d="M0 10 A1 1 \##(rotation) 0 \##(sweep) 20 10 Z"/>"##,
            ##"<path fill="#FF0000" d="M20 10 A1 1 \##(rotation) 0 \##(sweep) 0 10 Z"/>"##,
            ##"<path fill="#FF0000" d="M10 0 A1 1 \##(rotation) 0 \##(sweep) 10 20 Z"/>"##,
            ##"<path fill="#FF0000" d="M10 20 A1 1 \##(rotation) 0 \##(sweep) 10 0 Z"/>"##,
            ##"<path fill="#FF0000" d="M10 20 A1 1 \##(rotation) 1 \##(sweep) 10 0 Z"/>"##,
        ]

        for body in bodies {
            let image = try #require(render(svg(body)))
            #expect(image.size == CGSize(width: 20, height: 20))
        }
    }

    @Test
    func imageScalesNonUniformlyWhenTwoArgumentsAreGiven() throws {
        let body = ##"<rect width="5" height="5" fill="#FF0000" transform="scale(2, 4)"/>"##
        let image = try #require(render(svg(body)))

        expectColor(try pixel(in: image, x: 8, y: 18), r: 255, g: 0, b: 0)
        expectColor(try pixel(in: image, x: 12, y: 5), r: 0, g: 0, b: 0, a: 0)
    }

    @Test
    func imageHandlesInvalidUTF8AfterTheSVGHeader() {
        var data = Data(##"<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20">"##.utf8)
        data.append(Data(repeating: 0x20, count: 1100))
        data.append(0xFF)
        data.append(Data(##"<rect width="20" height="20" fill="#FF0000"/></svg>"##.utf8))

        #expect(render(data) == nil)
    }

    @Test(arguments: [0, 1])
    func imageSupportsLargeArcsWithPositiveSweep(sweep: Int) throws {
        let bodies = [
            ##"<path fill="#FF0000" d="M5 10 A15 15 0 1 \##(sweep) 15 10 Z"/>"##,
            ##"<path fill="#FF0000" d="M15 10 A15 15 0 1 \##(sweep) 5 10 Z"/>"##,
            ##"<path fill="#FF0000" d="M10 3 A12 8 20 1 \##(sweep) 10 17 Z"/>"##,
        ]

        for body in bodies {
            let image = try #require(render(svg(body)))
            #expect(image.size == CGSize(width: 20, height: 20))
        }
    }
}
