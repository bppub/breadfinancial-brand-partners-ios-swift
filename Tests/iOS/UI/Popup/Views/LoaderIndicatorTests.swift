//------------------------------------------------------------------------------
//  File:          LoaderIndicatorTests.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  7 2026 Bread Financial
//------------------------------------------------------------------------------

import Testing
import UIKit

@testable import BreadPartners

@Suite
@MainActor
struct LoaderIndicatorTests {
    @Test
    func createsColoredAnimatedBallsAndRotation() {
        let color = UIColor(red: 0.1, green: 0.7, blue: 0.6, alpha: 1)
        let indicator = makeIndicator(color: color)
        let balls = indicator.layer.sublayers ?? []

        #expect(balls.count == 8)
        #expect(
            balls.allSatisfy { ball in
                guard let backgroundColor = ball.backgroundColor else { return false }
                return UIColor(cgColor: backgroundColor).isEqual(color)
            }
        )
        #expect(balls.allSatisfy { $0.animation(forKey: "ballAnimation") != nil })
        #expect(indicator.layer.animation(forKey: "rotation") != nil)
    }

    @Test
    func stopAndStartRestoresAllAnimations() {
        let indicator = makeIndicator(color: UIColor(red: 0.1, green: 0.7, blue: 0.6, alpha: 1))
        let balls = indicator.layer.sublayers ?? []

        indicator.stopAnimating()

        #expect(balls.allSatisfy { $0.isHidden })
        #expect(balls.allSatisfy { $0.animation(forKey: "ballAnimation") == nil })
        #expect(indicator.layer.animation(forKey: "rotation") == nil)

        indicator.startAnimating()

        #expect(balls.allSatisfy { !$0.isHidden })
        #expect(balls.allSatisfy { $0.animation(forKey: "ballAnimation") != nil })
        #expect(indicator.layer.animation(forKey: "rotation") != nil)
    }

    private func makeIndicator(color: UIColor) -> LoaderIndicator {
        LoaderIndicator(
            frame: CGRect(x: 0, y: 0, width: 100, height: 100),
            color: color
        )
    }
}
