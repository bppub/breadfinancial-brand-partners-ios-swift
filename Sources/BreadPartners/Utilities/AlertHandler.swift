////------------------------------------------------------------------------------
////  File:          AlertHandler.swift
////  Author(s):     Bread Financial
////  Date:          27 March 2025
////
////  Descriptions:  This file is part of the BreadPartnersSDK for iOS,
////  providing UI components and functionalities to integrate Bread Financial
////  services into partner applications.
////
////  © 2025 Bread Financial
////------------------------------------------------------------------------------
//
//import UIKit
//
///// Class responsible for displaying alerts triggered by errors or events.
/////
///// It provides options to:
///// - Completely suppress all alerts
///// - Suppress only alerts triggered during RTPS flow
//internal actor AlertHandler:Sendable {
//
//    private var alertController: UIAlertController?
//    private var windowScene: UIWindowScene?
//    private var shouldShowAlert: Bool = false
//
//    init(windowScene: UIWindowScene?) {
//        self.windowScene = windowScene
//    }
//
//    private var rtpsFlow: Bool = false
//    private var logger: Logger?
//    var callback: (BreadPartnerEvents) -> Void = { _ in }
//
//    func setUpAlerts(
//        _ rtpsFlow: Bool = false, _ logger: Logger?,
//        _ callback: @escaping (
//            BreadPartnerEvents
//        ) -> Void
//    ) {
//        self.rtpsFlow = rtpsFlow
//        self.logger = logger
//        self.callback = callback
//    }
//
//    /// Displays or updates a custom alert dialog with a title and message.
//    func showAlert(title: String, message: String, showOkButton: Bool) async {
//        callback(
//            .sdkError(
//                error: NSError(
//                    domain: "", code: 500,
//                    userInfo: [NSLocalizedDescriptionKey: message])))
//        if !shouldShowAlert {
//            return
//        }
//        // If an alert is already being presented, dismiss it before showing a new one
//        if let existingAlert = alertController {
//            await existingAlert.dismiss(animated: true)
//        }
//
//        await presentAlert(
//            title: title, message: message, showOkButton: showOkButton)
//    }
//
//    /// Helper method to present the alert asynchronously.
//    private func presentAlert(
//        title: String, message: String, showOkButton: Bool
//    ) async {
//        alertController = await UIAlertController(
//            title: title, message: message, preferredStyle: .alert)
//
//        if showOkButton {
//            let okAction = await UIAlertAction(
//                title: Constants.okButton, style: .default)
//            await alertController?.addAction(okAction)
//        }
//
//        guard let windowScene = windowScene else { return }
//        if let rootViewController = await windowScene.windows.first?
//            .rootViewController
//        {
//            var topController = rootViewController
//            while let presentedVC = await topController.presentedViewController {
//                topController = presentedVC
//            }
//            await topController.present(
//                alertController!, animated: true, completion: nil)
//        }
//    }
//
//    /// Hides the currently displayed custom alert dialog.
//    func hideAlert() async{
//        guard let alertController = alertController else { return }
//        await alertController.dismiss(animated: true)
//        self.alertController = nil
//    }
//}
