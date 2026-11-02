//------------------------------------------------------------------------------
//  File:          QuickLookPDFPresenterTests.swift
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
import QuickLook
import Testing
import UIKit

@testable import BreadPartners

@MainActor
@Suite
struct QuickLookPDFPresenterTests {
    @Test
    func doesNotPresentOrDismissWhenNoViewControllerIsAvailable() {
        let presenter = QuickLookPDFPresenter(rootViewControllerProvider: { nil })
        var didDismiss = false

        let didPresent = presenter.present(
            pdfURL: URL(fileURLWithPath: "/tmp/disclosure.pdf"),
            onDismiss: { didDismiss = true }
        )

        #expect(!didPresent)
        #expect(!didDismiss)
    }

    @Test
    func ignoresDismissalFromUnrelatedPreviewController() throws {
        let viewController = PresentedViewControllerStub()
        let presenter = QuickLookPDFPresenter(rootViewControllerProvider: { viewController })
        let initialPreview = QLPreviewController()
        let pdfURL = URL(fileURLWithPath: "/tmp/disclosure.pdf")
        var dismissalCount = 0

        #expect(presenter.numberOfPreviewItems(in: initialPreview) == 0)
        #expect(
            presenter.present(
                pdfURL: pdfURL,
                onDismiss: { dismissalCount += 1 }
            )
        )

        let activePreview = try #require(viewController.presentedController as? QLPreviewController)
        #expect(presenter.numberOfPreviewItems(in: activePreview) == 1)
        #expect(presenter.previewController(activePreview, previewItemAt: 0).previewItemURL == pdfURL)

        presenter.previewControllerDidDismiss(QLPreviewController())

        #expect(dismissalCount == 0)
        #expect(presenter.numberOfPreviewItems(in: activePreview) == 1)

        presenter.previewControllerDidDismiss(activePreview)

        #expect(dismissalCount == 1)
        #expect(presenter.numberOfPreviewItems(in: activePreview) == 0)
    }

    @Test
    func presentsFromDeepestPresentedViewController() {
        let root = PresentedViewControllerStub()
        let presented = PresentedViewControllerStub()
        let deepest = PresentedViewControllerStub()
        root.nextPresentedViewController = presented
        presented.nextPresentedViewController = deepest
        let presenter = QuickLookPDFPresenter(rootViewControllerProvider: { root })

        #expect(
            presenter.present(
                pdfURL: URL(fileURLWithPath: "/tmp/disclosure.pdf"),
                onDismiss: {}
            )
        )

        #expect(root.presentedController == nil)
        #expect(presented.presentedController == nil)
        #expect(deepest.presentedController is QLPreviewController)
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
