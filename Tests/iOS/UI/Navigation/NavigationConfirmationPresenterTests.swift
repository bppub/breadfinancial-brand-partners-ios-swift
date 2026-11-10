//------------------------------------------------------------------------------
//  File:          NavigationConfirmationPresenterTests.swift
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
struct NavigationConfirmationPresenterTests {
    @Test
    func returnsFalseWhenNoRootViewControllerIsAvailable() {
        let presenter = UIKitNavigationConfirmationPresenter(
            rootViewControllerProvider: { nil }
        )

        let didPresent = presenter.presentNavigationConfirmation(
            onLeave: {},
            onStay: {}
        )

        #expect(!didPresent)
    }

    @Test
    func presentsConfirmationFromDeepestPresentedViewController() {
        let root = PresentedViewControllerStub()
        let presented = PresentedViewControllerStub()
        let deepest = PresentedViewControllerStub()
        root.nextPresentedViewController = presented
        presented.nextPresentedViewController = deepest
        let presenter = UIKitNavigationConfirmationPresenter(
            rootViewControllerProvider: { root }
        )

        let didPresent = presenter.presentNavigationConfirmation(
            onLeave: {},
            onStay: {}
        )

        #expect(didPresent)
        #expect(root.presentedController == nil)
        #expect(presented.presentedController == nil)
        #expect(deepest.presentedController is UIAlertController)
    }
}

@MainActor
private final class PresentedViewControllerStub: UIViewController {
    var nextPresentedViewController: UIViewController?
    private(set) var presentedController: UIViewController?

    override var presentedViewController: UIViewController? {
        nextPresentedViewController ?? presentedController
    }

    override func present(
        _ viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: (() -> Void)? = nil
    ) {
        presentedController = viewControllerToPresent
        completion?()
    }
}
