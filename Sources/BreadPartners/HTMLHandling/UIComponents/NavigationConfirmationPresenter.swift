//------------------------------------------------------------------------------
//  File:          NavigationConfirmationPresenter.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import UIKit

@MainActor
protocol NavigationConfirmationPresenting {
    func presentNavigationConfirmation(
        onLeave: @escaping () -> Void,
        onStay: @escaping () -> Void
    ) -> Bool
}

@MainActor
struct UIKitNavigationConfirmationPresenter: NavigationConfirmationPresenting {
    private let rootViewControllerProvider: @MainActor () -> UIViewController?

    init(
        rootViewControllerProvider: @escaping @MainActor () -> UIViewController? = {
            UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
                .first
        }
    ) {
        self.rootViewControllerProvider = rootViewControllerProvider
    }

    func presentNavigationConfirmation(
        onLeave: @escaping () -> Void,
        onStay: @escaping () -> Void
    ) -> Bool {
        guard let topViewController = topViewController() else {
            return false
        }

        let alert = UIAlertController(
            title: Constants.confirmNavigationTitle,
            message: Constants.confirmNavigationMessage,
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(title: Constants.confirmNavigationStayButton, style: .cancel) { _ in
                onStay()
            })
        alert.addAction(
            UIAlertAction(title: Constants.confirmNavigationLeaveButton, style: .destructive) { _ in
                onLeave()
            })

        topViewController.present(alert, animated: true)

        return true
    }

    private func topViewController() -> UIViewController? {
        var top = rootViewControllerProvider()

        while let presented = top?.presentedViewController {
            top = presented
        }

        return top
    }
}
