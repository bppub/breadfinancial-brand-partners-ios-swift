//------------------------------------------------------------------------------
//  File:          PopupLoadingViewTests.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Testing
import UIKit
@testable import BreadPartners

@Suite
@MainActor
struct PopupLoadingViewTests {
    @Test
    func centersIndicatorAndControlsItsAnimation() throws {
        let parentView = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        let loadingView = PopupLoadingView(color: .systemBlue)
        loadingView.install(in: parentView)
        parentView.layoutIfNeeded()

        let indicator = try #require(loadingView.subviews.first as? LoaderIndicator)
        #expect(loadingView.frame.width == 50)
        #expect(loadingView.frame.height == 50)
        #expect(loadingView.frame.midX == parentView.bounds.midX)
        #expect(loadingView.frame.midY == parentView.bounds.midY)
        #expect(loadingView.isHidden)
        #expect(indicator.layer.animation(forKey: "rotation") == nil)

        loadingView.startAnimating()

        #expect(!loadingView.isHidden)
        #expect(indicator.layer.animation(forKey: "rotation") != nil)

        loadingView.stopAnimating()

        #expect(loadingView.isHidden)
        #expect(indicator.layer.animation(forKey: "rotation") == nil)
    }
}
