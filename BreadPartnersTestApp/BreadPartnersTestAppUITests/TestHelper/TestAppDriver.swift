//------------------------------------------------------------------------------
//  File:          TestAppDriver.swift
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
import XCTest

extension XCUIApplication {
    /// Launches the app, then wipes its saved data so tests don't share state.
    func launchFresh(file: StaticString = #filePath, line: UInt = #line) {
        launch()
        resetAppData(file: file, line: line)
    }

    /// Clears the app's saved data by tapping the Reset tab's button, then returns to the Placement tab.
    /// Call after `launch()` so each test starts from the same state.
    func resetAppData(file: StaticString = #filePath, line: UInt = #line) {
        let resetTab = tabBars.buttons["Reset"]
        guard resetTab.waitForExistence(timeout: 10) else {
            XCTFail("Reset tab not found", file: file, line: line)
            return
        }
        resetTab.tap()

        let resetButton = buttons["Reset App Data"]
        guard resetButton.waitForExistence(timeout: 5) else {
            XCTFail("Reset App Data button not found", file: file, line: line)
            return
        }
        resetButton.tap()

        XCTAssertTrue(
            staticTexts["App data cleared."].waitForExistence(timeout: 5),
            "App data was not cleared", file: file, line: line)

        tabBars.buttons["Placement"].tap()
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

    private func focus(_ field: XCUIElement, maxScrolls: Int) -> Bool {
        var scrolls = 0
        while !field.isHittable && scrolls < maxScrolls {
        scrollContent(up: true)
            scrolls += 1
        }

        guard field.isHittable else { return false }

        field.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.5)).tap()

        let keyboard = XCUIApplication().keyboards.firstMatch
        return keyboard.waitForExistence(timeout: 2)
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
}
