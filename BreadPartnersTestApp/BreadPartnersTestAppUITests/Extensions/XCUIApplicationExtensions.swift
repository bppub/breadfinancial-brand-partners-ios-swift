//
//  XCUIApplicationExtensions.swift
//  BreadPartnersTestApp
//
//  Created by Joncarlos Tavarez on 10/20/26.
//

import Foundation
import XCTest

extension XCUIApplication {
    /// Configures the app to serve `stubs` for matching requests during this launch.
    /// Call before `launch()`.
    ///
    /// Each stub is encoded as `match|||statusCode|||base64json|||base64headers`.
    func enableHTTPStubs(_ stubs: [HTTPStub]) {
        launchEnvironment[StubProtocolKeys.enableKey] = StubProtocolKeys.enabledValue
        launchEnvironment[StubProtocolKeys.stubsKey] = stubs
            .map { stub in
                [
                    stub.match,
                    String(stub.statusCode),
                    stub.json.base64EncodedString(),
                    Self.encodeHeaders(stub.headers),
                ].joined(separator: StubProtocolKeys.fieldSeparator)
            }
            .joined(separator: StubProtocolKeys.entrySeparator)
    }

    /// Expands the section, types each value into the text field with that placeholder title, then collapses it.
    /// Pass pairs in on-screen order; pickers and toggles are not handled.
    func fillDisclosureSection(
        _ sectionTitle: String,
        with values: KeyValuePairs<String, String>,
        maxScrolls: Int = 12,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let header = buttons[sectionTitle]
        guard header.waitForExistence(timeout: 10) else {
            XCTFail("Section '\(sectionTitle)' not found", file: file, line: line)
            return
        }

        // Idempotent: only expand if the first field isn't already showing.
        if let first = values.first, !textFields[first.key].exists {
            header.tap()
        }

        for (name, value) in values {
            let field = textFields[name]

            guard focus(field, maxScrolls: maxScrolls) else {
                XCTFail("Field '\(name)' could not be focused", file: file, line: line)
                return
            }

            // An empty field reports its placeholder as its value.
            if let current = field.value as? String, !current.isEmpty, current != name {
                field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
            }
            // Return resigns focus so the next field is tapped with no keyboard-avoidance scroll in flight.
            field.typeText(value + "\n")
            waitForKeyboardToDismiss()
        }

        if let first = values.first, !collapse(header, firstField: textFields[first.key], maxScrolls: maxScrolls) {
            XCTFail("Section '\(sectionTitle)' did not collapse", file: file, line: line)
        }
    }

    /// Taps the header and confirms the section's first field is gone, retrying since a tap can be swallowed mid-scroll.
    private func collapse(_ header: XCUIElement, firstField: XCUIElement, maxScrolls: Int, attempts: Int = 3) -> Bool {
        for _ in 0..<attempts {
            // A header under the status bar reports hittable, but a tap there scrolls to top instead of toggling.
            let minHeaderY: CGFloat = 80
            var ups = 0
            var lastY: CGFloat?
            while !(header.exists && header.isHittable && header.frame.minY >= minHeaderY) && ups < maxScrolls {
                // Stop once the list is at its top and the header no longer moves.
                if header.exists, header.frame.minY == lastY { break }
                lastY = header.exists ? header.frame.minY : nil
                scrollContent(up: false)
                ups += 1
            }
            guard header.exists && header.isHittable else { return false }

            header.tap()

            // The first row sits directly under the header, so it is on screen whenever the section is open.
            let deadline = Date().addingTimeInterval(3)
            while firstField.exists && Date() < deadline {
                usleep(100_000)
            }
            if !firstField.exists { return true }
        }
        return false
    }

    /// Scrolls the field above the keyboard and taps it until it actually holds keyboard focus.
    private func focus(_ field: XCUIElement, maxScrolls: Int, attempts: Int = 3) -> Bool {
        for _ in 0..<attempts {
            var scrolls = 0
            while !isReachableAboveKeyboard(field) && scrolls < maxScrolls {
                scrollContent(up: true)
                scrolls += 1
            }
            guard isReachableAboveKeyboard(field) else { return false }

            // Right edge puts the caret at the end so backspaces clear the whole value.
            field.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.5)).tap()

            let deadline = Date().addingTimeInterval(2)
            while Date() < deadline {
                // Private KVC key; the public API has no focus query.
                if field.value(forKey: "hasKeyboardFocus") as? Bool == true { return true }
                usleep(100_000)
            }
        }
        return false
    }

    private func waitForKeyboardToDismiss(timeout: TimeInterval = 2) {
        let deadline = Date().addingTimeInterval(timeout)
        while keyboards.firstMatch.exists && Date() < deadline {
            usleep(100_000)
        }
    }

    /// `isHittable` ignores the keyboard (separate window), so also require the field to sit above it.
    private func isReachableAboveKeyboard(_ element: XCUIElement) -> Bool {
        guard element.exists, element.isHittable else { return false }
        let keyboard = keyboards.firstMatch
        return !keyboard.exists || element.frame.maxY < keyboard.frame.minY
    }

    /// Drag instead of `swipeUp()`, whose fling can overshoot; short going down to a field, long coming back to the header.
    private func scrollContent(up: Bool) {
        let top = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: up ? 0.35 : 0.25))
        let bottom = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: up ? 0.55 : 0.8))
        (up ? bottom : top).press(forDuration: 0.05, thenDragTo: up ? top : bottom)
    }

    /// Encodes a headers dictionary as base64 JSON so it survives the field and
    /// entry separators used in the launch-environment payload. Returns an empty
    /// string when encoding fails, which the app treats as "use default headers".
    private static func encodeHeaders(_ headers: [String: String]) -> String {
        guard
            !headers.isEmpty,
            let data = try? JSONEncoder().encode(headers)
        else { return "" }
        return data.base64EncodedString()
    }
}
