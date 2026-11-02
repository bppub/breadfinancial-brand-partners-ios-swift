//------------------------------------------------------------------------------
//  File:          QuickLookPDFPresenter.swift
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
import UIKit

@MainActor
protocol PDFPresenting {
    func present(pdfURL: URL, onDismiss: @escaping () -> Void) -> Bool
}

@MainActor
final class QuickLookPDFPresenter: NSObject, PDFPresenting,
    QLPreviewControllerDataSource, @preconcurrency QLPreviewControllerDelegate
{
    private let rootViewControllerProvider: @MainActor () -> UIViewController?
    private var activePreview: QLPreviewController?
    private var activePDFURL: URL?
    private var onDismiss: (() -> Void)?

    init(
        rootViewControllerProvider: @escaping @MainActor () -> UIViewController? = {
            UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
                .first
        }
    ) {
        self.rootViewControllerProvider = rootViewControllerProvider
    }

    func present(pdfURL: URL, onDismiss: @escaping () -> Void) -> Bool {
        guard let viewController = topViewController() else { return false }

        let preview = QLPreviewController()
        preview.dataSource = self
        preview.delegate = self
        preview.modalPresentationStyle = .pageSheet
        activePreview = preview
        activePDFURL = pdfURL
        self.onDismiss = onDismiss
        viewController.present(preview, animated: true)
        return true
    }

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        activePDFURL == nil ? 0 : 1
    }

    func previewController(
        _ controller: QLPreviewController,
        previewItemAt index: Int
    ) -> QLPreviewItem {
        activePDFURL! as QLPreviewItem
    }

    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        guard controller === activePreview else { return }
        let dismissal = onDismiss
        activePreview = nil
        activePDFURL = nil
        onDismiss = nil
        dismissal?()
    }

    private func topViewController() -> UIViewController? {
        var top = rootViewControllerProvider()

        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
