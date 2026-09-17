//------------------------------------------------------------------------------
//  File:          SVGImageRenderer.swift
//  Author(s):     Bread Financial
//  Date:          17 September 2026
//
//  Descriptions:  A minimal, dependency-free SVG parser and rasterizer used
//  to render brand/partner logos delivered as SVG. Only the common subset of
//  SVG needed for flat, single-color vector logos is supported: <svg>, <g>,
//  <path>, <rect>, <circle>, <ellipse>, <line>, <polygon>, <polyline>,
//  "transform" (translate/scale/rotate/matrix/skewX/skewY), and basic
//  "fill"/"stroke"/"opacity" styling. Gradients, filters, clip-paths, text,
//  <use>/<defs> references, CSS <style> blocks, and animations are
//  intentionally out of scope, since they are not needed for static logos
//  and would meaningfully increase the surface area of this file.
//
//  This intentionally avoids WKWebView (no JavaScript execution risk from
//  untrusted, partner-supplied SVG content) and third-party dependencies.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

import UIKit

enum SVGImageRenderer {

    // MARK: - Public API

    /// Quickly sniffs whether the given data looks like an SVG document.
    static func isSVG(data: Data) -> Bool {
        guard let head = String(data: data.prefix(1024), encoding: .utf8)?.lowercased()
        else { return false }
        return head.contains("<svg")
    }

    /// Parses and rasterizes SVG data into a `UIImage`.
    /// - Parameters:
    ///   - data: Raw SVG document bytes.
    ///   - targetSize: Desired output size in points. If `.zero`, the SVG's
    ///     own intrinsic size (from `viewBox`, or `width`/`height`) is used.
    /// - Returns: A rasterized `UIImage`, or `nil` if the data isn't a
    ///   parseable SVG document.
    static func image(from data: Data, targetSize: CGSize) -> UIImage? {
        guard isSVG(data: data) else { return nil }

        let parser = SVGDocumentParser()
        guard let document = parser.parse(data: data), !document.shapes.isEmpty else {
            return nil
        }

        let sourceSize = document.intrinsicSize
        guard sourceSize.width > 0, sourceSize.height > 0 else { return nil }

        let outputSize = (targetSize.width > 0 && targetSize.height > 0) ? targetSize : sourceSize
        let scaleX = outputSize.width / sourceSize.width
        let scaleY = outputSize.height / sourceSize.height
        let origin = document.viewBoxOrigin

        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: outputSize, format: format)

        return renderer.image { rendererContext in
            let context = rendererContext.cgContext
            context.scaleBy(x: scaleX, y: scaleY)
            context.translateBy(x: -origin.x, y: -origin.y)
            for shape in document.shapes {
                shape.draw(in: context)
            }
        }
    }
}

// MARK: - Document model

private struct SVGShape {
    let path: CGPath
    let style: SVGStyle

    func draw(in context: CGContext) {
        guard style.opacity > 0 else { return }
        context.saveGState()

        if case .color(let color, let alpha) = style.fill {
            context.addPath(path)
            context.setFillColor(color.copy(alpha: alpha * style.opacity) ?? color)
            context.fillPath(using: style.fillRule)
        }

        if case .color(let strokeColor, let alpha) = style.stroke, style.strokeWidth > 0 {
            context.addPath(path)
            context.setStrokeColor(strokeColor.copy(alpha: alpha * style.opacity) ?? strokeColor)
            context.setLineWidth(style.strokeWidth)
            context.strokePath()
        }

        context.restoreGState()
    }
}

private enum SVGPaint {
    case none
    case color(CGColor, alpha: CGFloat)
}

private struct SVGStyle {
    var fill: SVGPaint = .color(UIColor.black.cgColor, alpha: 1)
    var stroke: SVGPaint = .none
    var strokeWidth: CGFloat = 1
    var opacity: CGFloat = 1
    var fillRule: CGPathFillRule = .winding

    /// Merges attributes found on a child element on top of inherited style.
    func merging(attributes: [String: String]) -> SVGStyle {
        var style = self
        if let fillValue = attributes["fill"] {
            style.fill = SVGStyle.parsePaint(fillValue, fallback: style.fill)
        }
        if let strokeValue = attributes["stroke"] {
            style.stroke = SVGStyle.parsePaint(strokeValue, fallback: style.stroke)
        }
        if let strokeWidthValue = attributes["stroke-width"], let value = Double(strokeWidthValue) {
            style.strokeWidth = CGFloat(value)
        }
        if let opacityValue = attributes["opacity"], let value = Double(opacityValue) {
            style.opacity = style.opacity * CGFloat(max(0, min(1, value)))
        }
        if let fillOpacityValue = attributes["fill-opacity"], let value = Double(fillOpacityValue),
           case .color(let color, _) = style.fill {
            style.fill = .color(color, alpha: CGFloat(max(0, min(1, value))))
        }
        if let fillRuleValue = attributes["fill-rule"] {
            style.fillRule = fillRuleValue == "evenodd" ? .evenOdd : .winding
        }
        // Bare "style" attribute, e.g. style="fill:#fff;stroke:none"
        if let inlineStyle = attributes["style"] {
            let declarations = inlineStyle.split(separator: ";")
            for declaration in declarations {
                let parts = declaration.split(separator: ":", maxSplits: 1)
                guard parts.count == 2 else { continue }
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let value = parts[1].trimmingCharacters(in: .whitespaces)
                switch key {
                case "fill": style.fill = SVGStyle.parsePaint(value, fallback: style.fill)
                case "stroke": style.stroke = SVGStyle.parsePaint(value, fallback: style.stroke)
                case "opacity":
                    if let doubleValue = Double(value) {
                        style.opacity = style.opacity * CGFloat(max(0, min(1, doubleValue)))
                    }
                default: break
                }
            }
        }
        return style
    }

    private static func parsePaint(_ value: String, fallback: SVGPaint) -> SVGPaint {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed == "none" { return .none }
        if trimmed == "currentColor" || trimmed.isEmpty { return fallback }
        if let color = SVGColorParser.color(from: trimmed) {
            return .color(color, alpha: 1)
        }
        return fallback
    }
}

private struct SVGDocument {
    var shapes: [SVGShape] = []
    var viewBoxOrigin: CGPoint = .zero
    var viewBoxSize: CGSize?
    var widthHeight: CGSize?

    var intrinsicSize: CGSize {
        viewBoxSize ?? widthHeight ?? CGSize(width: 200, height: 200)
    }
}

// MARK: - XML parsing

private final class SVGDocumentParser: NSObject, XMLParserDelegate {
    /// Elements whose content is a *definition* (referenced elsewhere via
    /// "url(#id)" or `<use>`, neither of which this minimal parser
    /// supports) rather than something drawn in place. Without this,
    /// shapes declared only for reuse (e.g. a `<rect>` inside a
    /// `<clipPath>` inside `<defs>`) would incorrectly be rendered as
    /// visible shapes, appearing as unexpected solid squares/paths.
    private static let nonRenderingElements: Set<String> = [
        "defs", "clippath", "symbol", "mask", "pattern",
        "lineargradient", "radialgradient", "style", "title", "desc",
    ]

    private var document = SVGDocument()
    private var styleStack: [SVGStyle] = [SVGStyle()]
    private var transformStack: [CGAffineTransform] = [.identity]
    private var suppressStack: [Bool] = [false]
    private var didParseError = false

    func parse(data: Data) -> SVGDocument? {
        let parser = XMLParser(data: data)
        parser.delegate = self
        guard parser.parse(), !didParseError else { return nil }
        return document
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        let currentStyle = styleStack.last ?? SVGStyle()
        let mergedStyle = currentStyle.merging(attributes: attributeDict)
        let localTransform = SVGTransformParser.transform(from: attributeDict["transform"])
        let combinedTransform = localTransform.concatenating(transformStack.last ?? .identity)
        let parentSuppressed = suppressStack.last ?? false
        let suppressed = parentSuppressed || Self.nonRenderingElements.contains(elementName.lowercased())

        switch elementName {
        case "svg":
            parseSVGRoot(attributes: attributeDict)
        case "g", "svg", "symbol":
            break
        default:
            break
        }

        if !suppressed, let path = SVGShapeFactory.path(for: elementName, attributes: attributeDict) {
            var mutableTransform = combinedTransform
            let transformedPath = path.copy(using: &mutableTransform) ?? path
            document.shapes.append(SVGShape(path: transformedPath, style: mergedStyle))
        }

        styleStack.append(mergedStyle)
        transformStack.append(combinedTransform)
        suppressStack.append(suppressed)
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if styleStack.count > 1 { styleStack.removeLast() }
        if transformStack.count > 1 { transformStack.removeLast() }
        if suppressStack.count > 1 { suppressStack.removeLast() }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        didParseError = true
    }

    private func parseSVGRoot(attributes: [String: String]) {
        if let viewBoxValue = attributes["viewBox"] {
            let parts = viewBoxValue
                .split(whereSeparator: { $0 == " " || $0 == "," })
                .compactMap { Double($0) }
            if parts.count == 4 {
                document.viewBoxOrigin = CGPoint(x: parts[0], y: parts[1])
                document.viewBoxSize = CGSize(width: parts[2], height: parts[3])
            }
        }
        if let widthValue = attributes["width"], let heightValue = attributes["height"],
           let width = SVGLengthParser.length(from: widthValue),
           let height = SVGLengthParser.length(from: heightValue) {
            document.widthHeight = CGSize(width: width, height: height)
        }
    }
}

// MARK: - Shape construction

private enum SVGShapeFactory {
    static func path(for elementName: String, attributes: [String: String]) -> CGPath? {
        switch elementName {
        case "path":
            guard let data = attributes["d"] else { return nil }
            return SVGPathDataParser.path(from: data)

        case "rect":
            let x = SVGLengthParser.length(from: attributes["x"]) ?? 0
            let y = SVGLengthParser.length(from: attributes["y"]) ?? 0
            guard let width = SVGLengthParser.length(from: attributes["width"]),
                  let height = SVGLengthParser.length(from: attributes["height"]) else { return nil }
            let rx = SVGLengthParser.length(from: attributes["rx"])
            let ry = SVGLengthParser.length(from: attributes["ry"])
            let cornerRadius = rx ?? ry ?? 0
            let rect = CGRect(x: x, y: y, width: width, height: height)
            return cornerRadius > 0
                ? CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
                : CGPath(rect: rect, transform: nil)

        case "circle":
            guard let cx = SVGLengthParser.length(from: attributes["cx"]),
                  let cy = SVGLengthParser.length(from: attributes["cy"]),
                  let radius = SVGLengthParser.length(from: attributes["r"]) else { return nil }
            let rect = CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2)
            return CGPath(ellipseIn: rect, transform: nil)

        case "ellipse":
            guard let cx = SVGLengthParser.length(from: attributes["cx"]),
                  let cy = SVGLengthParser.length(from: attributes["cy"]),
                  let rx = SVGLengthParser.length(from: attributes["rx"]),
                  let ry = SVGLengthParser.length(from: attributes["ry"]) else { return nil }
            let rect = CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2)
            return CGPath(ellipseIn: rect, transform: nil)

        case "line":
            guard let x1 = SVGLengthParser.length(from: attributes["x1"]),
                  let y1 = SVGLengthParser.length(from: attributes["y1"]),
                  let x2 = SVGLengthParser.length(from: attributes["x2"]),
                  let y2 = SVGLengthParser.length(from: attributes["y2"]) else { return nil }
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x1, y: y1))
            path.addLine(to: CGPoint(x: x2, y: y2))
            return path

        case "polygon", "polyline":
            guard let pointsValue = attributes["points"] else { return nil }
            let coordinates = pointsValue
                .split(whereSeparator: { $0 == " " || $0 == "," || $0 == "\n" })
                .compactMap { Double($0) }
            guard coordinates.count >= 4 else { return nil }
            let path = CGMutablePath()
            path.move(to: CGPoint(x: coordinates[0], y: coordinates[1]))
            var index = 2
            while index + 1 < coordinates.count {
                path.addLine(to: CGPoint(x: coordinates[index], y: coordinates[index + 1]))
                index += 2
            }
            if elementName == "polygon" { path.closeSubpath() }
            return path

        default:
            return nil
        }
    }
}

// MARK: - Path data ("d" attribute) tokenizer

private enum SVGPathDataParser {
    static func path(from data: String) -> CGPath? {
        var scanner = PathDataScanner(data)
        let path = CGMutablePath()
        var current = CGPoint.zero
        var subpathStart = CGPoint.zero
        var lastControlPoint: CGPoint?
        var lastCommand: Character?

        while let command = scanner.nextCommand(previous: lastCommand) {
            let isRelative = command.isLowercase
            switch command.lowercased().first! {
            case "m":
                guard let point = scanner.nextPoint() else { return finalize(path) }
                current = isRelative ? current + point : point
                path.move(to: current)
                subpathStart = current
                lastControlPoint = nil
                // Subsequent coordinate pairs after 'M' are implicit 'L'.
                while let next = scanner.peekPoint() {
                    _ = scanner.nextPoint()
                    current = isRelative ? current + next : next
                    path.addLine(to: current)
                }
            case "l":
                while let point = scanner.nextPoint() {
                    current = isRelative ? current + point : point
                    path.addLine(to: current)
                }
                lastControlPoint = nil
            case "h":
                while let value = scanner.nextNumber() {
                    current = CGPoint(x: isRelative ? current.x + value : value, y: current.y)
                    path.addLine(to: current)
                }
                lastControlPoint = nil
            case "v":
                while let value = scanner.nextNumber() {
                    current = CGPoint(x: current.x, y: isRelative ? current.y + value : value)
                    path.addLine(to: current)
                }
                lastControlPoint = nil
            case "c":
                while let control1 = scanner.nextPoint(),
                      let control2 = scanner.nextPoint(),
                      let end = scanner.nextPoint() {
                    let c1 = isRelative ? current + control1 : control1
                    let c2 = isRelative ? current + control2 : control2
                    let endpoint = isRelative ? current + end : end
                    path.addCurve(to: endpoint, control1: c1, control2: c2)
                    lastControlPoint = c2
                    current = endpoint
                }
            case "s":
                while let control2 = scanner.nextPoint(), let end = scanner.nextPoint() {
                    let c1 = lastControlPoint.map { current + (current - $0) } ?? current
                    let c2 = isRelative ? current + control2 : control2
                    let endpoint = isRelative ? current + end : end
                    path.addCurve(to: endpoint, control1: c1, control2: c2)
                    lastControlPoint = c2
                    current = endpoint
                }
            case "q":
                while let control = scanner.nextPoint(), let end = scanner.nextPoint() {
                    let c = isRelative ? current + control : control
                    let endpoint = isRelative ? current + end : end
                    path.addQuadCurve(to: endpoint, control: c)
                    lastControlPoint = c
                    current = endpoint
                }
            case "t":
                while let end = scanner.nextPoint() {
                    let c = lastControlPoint.map { current + (current - $0) } ?? current
                    let endpoint = isRelative ? current + end : end
                    path.addQuadCurve(to: endpoint, control: c)
                    lastControlPoint = c
                    current = endpoint
                }
            case "a":
                while let radii = scanner.nextPoint(),
                      let rotation = scanner.nextNumber(),
                      let largeArcFlag = scanner.nextFlag(),
                      let sweepFlag = scanner.nextFlag(),
                      let end = scanner.nextPoint() {
                    let endpoint = isRelative ? current + end : end
                    SVGArcConverter.addArc(
                        to: path, from: current, to: endpoint,
                        radiusX: radii.x, radiusY: radii.y,
                        xAxisRotationDegrees: rotation,
                        largeArcFlag: largeArcFlag, sweepFlag: sweepFlag
                    )
                    current = endpoint
                    lastControlPoint = nil
                }
            case "z":
                path.closeSubpath()
                current = subpathStart
                lastControlPoint = nil
            default:
                return finalize(path)
            }
            lastCommand = command
        }
        return finalize(path)
    }

    private static func finalize(_ path: CGMutablePath) -> CGPath? {
        path.isEmpty ? nil : path
    }
}

private struct PathDataScanner {
    private let scalar: [Character]
    private var index = 0

    init(_ string: String) {
        self.scalar = Array(string)
    }

    mutating func nextCommand(previous: Character?) -> Character? {
        skipSeparators()
        guard index < scalar.count else { return nil }
        let character = scalar[index]
        if character.isLetter {
            index += 1
            return character
        }
        // Implicit repetition of the previous command (e.g. "L10 10 20 20").
        return previous
    }

    mutating func nextNumber() -> Double? {
        skipSeparators()
        guard index < scalar.count else { return nil }
        var end = index
        var seenDot = false
        var seenExponent = false
        if scalar[end] == "+" || scalar[end] == "-" { end += 1 }
        let start = end
        while end < scalar.count {
            let character = scalar[end]
            if character.isNumber {
                end += 1
            } else if character == "." && !seenDot {
                seenDot = true
                end += 1
            } else if (character == "e" || character == "E") && !seenExponent {
                seenExponent = true
                end += 1
                if end < scalar.count && (scalar[end] == "+" || scalar[end] == "-") { end += 1 }
            } else {
                break
            }
        }
        guard end > start else { return nil }
        let substring = String(scalar[index..<end])
        index = end
        return Double(substring)
    }

    mutating func nextFlag() -> Bool? {
        skipSeparators()
        guard index < scalar.count else { return nil }
        let character = scalar[index]
        guard character == "0" || character == "1" else { return nil }
        index += 1
        return character == "1"
    }

    mutating func nextPoint() -> CGPoint? {
        let savedIndex = index
        guard let x = nextNumber(), let y = nextNumber() else {
            index = savedIndex
            return nil
        }
        return CGPoint(x: x, y: y)
    }

    func peekPoint() -> CGPoint? {
        var copy = self
        return copy.nextPoint()
    }

    private mutating func skipSeparators() {
        while index < scalar.count, scalar[index] == " " || scalar[index] == "," || scalar[index] == "\n" || scalar[index] == "\t" {
            index += 1
        }
    }
}

private extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}

// MARK: - Elliptical arc ("A") to bezier conversion

private enum SVGArcConverter {
    /// Converts an SVG elliptical arc command into one or more cubic bezier
    /// curves appended to `path`, per the SVG 1.1 spec (F.6).
    static func addArc(
        to path: CGMutablePath,
        from start: CGPoint,
        to end: CGPoint,
        radiusX: Double,
        radiusY: Double,
        xAxisRotationDegrees: Double,
        largeArcFlag: Bool,
        sweepFlag: Bool
    ) {
        var rx = abs(radiusX)
        var ry = abs(radiusY)
        if rx == 0 || ry == 0 || (start.x == end.x && start.y == end.y) {
            path.addLine(to: end)
            return
        }

        let phi = xAxisRotationDegrees * .pi / 180
        let cosPhi = cos(phi)
        let sinPhi = sin(phi)

        let dx2 = (start.x - end.x) / 2
        let dy2 = (start.y - end.y) / 2
        let x1p = cosPhi * dx2 + sinPhi * dy2
        let y1p = -sinPhi * dx2 + cosPhi * dy2

        let lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
        if lambda > 1 {
            let scale = sqrt(lambda)
            rx *= scale
            ry *= scale
        }

        let sign: Double = (largeArcFlag != sweepFlag) ? 1 : -1
        let num = max(0, (rx * rx * ry * ry) - (rx * rx * y1p * y1p) - (ry * ry * x1p * x1p))
        let den = (rx * rx * y1p * y1p) + (ry * ry * x1p * x1p)
        let coefficient = den == 0 ? 0 : sign * sqrt(num / den)

        let cxp = coefficient * (rx * y1p / ry)
        let cyp = coefficient * -(ry * x1p / rx)

        let cx = cosPhi * cxp - sinPhi * cyp + (start.x + end.x) / 2
        let cy = sinPhi * cxp + cosPhi * cyp + (start.y + end.y) / 2

        func angle(_ ux: Double, _ uy: Double, _ vx: Double, _ vy: Double) -> Double {
            let dot = ux * vx + uy * vy
            let len = sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy))
            var result = len == 0 ? 0 : acos(max(-1, min(1, dot / len)))
            if (ux * vy - uy * vx) < 0 { result = -result }
            return result
        }

        let theta1 = angle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry)
        var deltaTheta = angle((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry)
        if !sweepFlag && deltaTheta > 0 { deltaTheta -= 2 * .pi }
        if sweepFlag && deltaTheta < 0 { deltaTheta += 2 * .pi }

        // Split into segments of at most 90 degrees for a good bezier approximation.
        let segmentCount = max(1, Int(ceil(abs(deltaTheta) / (.pi / 2))))
        let segmentDelta = deltaTheta / Double(segmentCount)
        let alpha = sin(segmentDelta) * (sqrt(4 + 3 * pow(tan(segmentDelta / 2), 2)) - 1) / 3

        var theta = theta1
        var currentPoint = start
        for _ in 0..<segmentCount {
            let nextTheta = theta + segmentDelta
            let cosTheta = cos(theta), sinTheta = sin(theta)
            let cosNext = cos(nextTheta), sinNext = sin(nextTheta)

            func ellipsePoint(_ t: Double, _ cosT: Double, _ sinT: Double) -> CGPoint {
                let x = cosPhi * rx * cosT - sinPhi * ry * sinT + cx
                let y = sinPhi * rx * cosT + cosPhi * ry * sinT + cy
                return CGPoint(x: x, y: y)
            }
            func ellipseTangent(_ cosT: Double, _ sinT: Double) -> CGPoint {
                let x = -cosPhi * rx * sinT - sinPhi * ry * cosT
                let y = -sinPhi * rx * sinT + cosPhi * ry * cosT
                return CGPoint(x: x, y: y)
            }

            let p2 = ellipsePoint(nextTheta, cosNext, sinNext)
            let tangent1 = ellipseTangent(cosTheta, sinTheta)
            let tangent2 = ellipseTangent(cosNext, sinNext)

            let control1 = CGPoint(x: currentPoint.x + alpha * tangent1.x, y: currentPoint.y + alpha * tangent1.y)
            let control2 = CGPoint(x: p2.x - alpha * tangent2.x, y: p2.y - alpha * tangent2.y)

            path.addCurve(to: p2, control1: control1, control2: control2)
            currentPoint = p2
            theta = nextTheta
        }
    }
}

// MARK: - Transform parsing ("transform" attribute)

private enum SVGTransformParser {
    static func transform(from value: String?) -> CGAffineTransform {
        guard let value else { return .identity }
        var result = CGAffineTransform.identity
        var scanner = TransformScanner(value)
        while let (name, args) = scanner.nextFunction() {
            let transform: CGAffineTransform
            switch name {
            case "translate":
                transform = CGAffineTransform(translationX: args.first ?? 0, y: args.count > 1 ? args[1] : 0)
            case "scale":
                let sx = args.first ?? 1
                let sy = args.count > 1 ? args[1] : sx
                transform = CGAffineTransform(scaleX: sx, y: sy)
            case "rotate":
                let degrees = args.first ?? 0
                let radians = degrees * .pi / 180
                if args.count >= 3 {
                    let cx = args[1], cy = args[2]
                    transform = CGAffineTransform(translationX: cx, y: cy)
                        .rotated(by: radians)
                        .translatedBy(x: -cx, y: -cy)
                } else {
                    transform = CGAffineTransform(rotationAngle: radians)
                }
            case "skewX":
                let radians = (args.first ?? 0) * .pi / 180
                transform = CGAffineTransform(a: 1, b: 0, c: tan(radians), d: 1, tx: 0, ty: 0)
            case "skewY":
                let radians = (args.first ?? 0) * .pi / 180
                transform = CGAffineTransform(a: 1, b: tan(radians), c: 0, d: 1, tx: 0, ty: 0)
            case "matrix":
                guard args.count == 6 else { continue }
                transform = CGAffineTransform(a: args[0], b: args[1], c: args[2], d: args[3], tx: args[4], ty: args[5])
            default:
                continue
            }
            result = transform.concatenating(result)
        }
        return result
    }
}

private struct TransformScanner {
    private let characters: [Character]
    private var index = 0

    init(_ string: String) {
        self.characters = Array(string)
    }

    mutating func nextFunction() -> (name: String, args: [CGFloat])? {
        skip { $0 == " " || $0 == "," }
        guard index < characters.count else { return nil }
        var name = ""
        while index < characters.count, characters[index].isLetter {
            name.append(characters[index])
            index += 1
        }
        guard !name.isEmpty else { return nil }
        skip { $0 == " " }
        guard index < characters.count, characters[index] == "(" else { return nil }
        index += 1
        var argsString = ""
        while index < characters.count, characters[index] != ")" {
            argsString.append(characters[index])
            index += 1
        }
        if index < characters.count { index += 1 } // skip ')'
        let args = argsString
            .split(whereSeparator: { $0 == " " || $0 == "," })
            .compactMap { Double($0) }
            .map { CGFloat($0) }
        return (name, args)
    }

    private mutating func skip(_ condition: (Character) -> Bool) {
        while index < characters.count, condition(characters[index]) {
            index += 1
        }
    }
}

// MARK: - Length / color parsing helpers

private enum SVGLengthParser {
    /// Parses a length value, stripping common unit suffixes. Percentage
    /// values are not supported and return `nil`.
    static func length(from value: String?) -> Double? {
        guard var trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        if trimmed.hasSuffix("%") { return nil }
        for unit in ["px", "pt", "pc", "mm", "cm", "in"] where trimmed.hasSuffix(unit) {
            trimmed.removeLast(unit.count)
            break
        }
        return Double(trimmed)
    }
}

private enum SVGColorParser {
    static func color(from value: String) -> CGColor? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if trimmed.hasPrefix("#") {
            return hexColor(trimmed)
        }
        if trimmed.hasPrefix("rgb") {
            return functionalColor(trimmed)
        }
        return namedColors[trimmed]
    }

    private static func hexColor(_ value: String) -> CGColor? {
        var hex = String(value.dropFirst())
        switch hex.count {
        case 3:
            hex = hex.map { "\($0)\($0)" }.joined()
        case 6, 8:
            break
        default:
            return nil
        }
        guard let intValue = UInt64(hex, radix: 16) else { return nil }
        let hasAlpha = hex.count == 8
        let red = CGFloat((intValue >> (hasAlpha ? 24 : 16)) & 0xFF) / 255.0
        let green = CGFloat((intValue >> (hasAlpha ? 16 : 8)) & 0xFF) / 255.0
        let blue = CGFloat((intValue >> (hasAlpha ? 8 : 0)) & 0xFF) / 255.0
        let alpha = hasAlpha ? CGFloat(intValue & 0xFF) / 255.0 : 1.0
        return UIColor(red: red, green: green, blue: blue, alpha: alpha).cgColor
    }

    private static func functionalColor(_ value: String) -> CGColor? {
        guard let openParen = value.firstIndex(of: "("), let closeParen = value.firstIndex(of: ")") else {
            return nil
        }
        let componentsString = value[value.index(after: openParen)..<closeParen]
        let components = componentsString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        guard components.count >= 3 else { return nil }

        func componentValue(_ text: String) -> CGFloat {
            if text.hasSuffix("%"), let percent = Double(text.dropLast()) {
                return CGFloat(percent) / 100.0
            }
            return CGFloat(Double(text) ?? 0) / 255.0
        }

        let red = componentValue(components[0])
        let green = componentValue(components[1])
        let blue = componentValue(components[2])
        let alpha: CGFloat = components.count > 3 ? CGFloat(Double(components[3]) ?? 1) : 1
        return UIColor(red: red, green: green, blue: blue, alpha: alpha).cgColor
    }

    /// A small set of CSS named colors commonly seen in brand logos.
    private static let namedColors: [String: CGColor] = [
        "black": UIColor.black.cgColor,
        "white": UIColor.white.cgColor,
        "red": UIColor.red.cgColor,
        "green": UIColor(red: 0, green: 0.5, blue: 0, alpha: 1).cgColor,
        "blue": UIColor.blue.cgColor,
        "yellow": UIColor.yellow.cgColor,
        "orange": UIColor.orange.cgColor,
        "purple": UIColor.purple.cgColor,
        "gray": UIColor.gray.cgColor,
        "grey": UIColor.gray.cgColor,
        "transparent": UIColor.clear.cgColor,
    ]
}
