////------------------------------------------------------------------------------
////  File:          RecaptchaManager.swift
////  Author(s):     Bread Financial
////  Date:          27 March 2025
////
////  Descriptions:  This file is part of the BreadPartners SDK for iOS,
////  providing UI components and functionalities to integrate Bread Financial
////  services into partner applications.
////
////  © 2025 Bread Financial
////------------------------------------------------------------------------------

@preconcurrency import RecaptchaEnterprise

/// `RecaptchaManager` handles the process of executing a reCAPTCHA for verifying user actions.
internal actor RecaptchaManager: @unchecked Sendable {

    static let shared = RecaptchaManager()
    private let logger: Logger
    private var recaptchaClient: RecaptchaClient? = nil

    private init(logger: Logger = Logger()) {
        self.logger = logger
    }

    func fetchRecaptchaClient(siteKey: String) async throws {
        if recaptchaClient != nil {
            return
        }
        do {
            self.recaptchaClient = try await Recaptcha.fetchClient(withSiteKey: siteKey)
        } catch let error as RecaptchaError {
            throw error
        }
    }

    func executeReCaptcha(
        siteKey: String,
        action: RecaptchaAction,
        timeout: Double = 10000,
        debug: Bool = false
    ) async throws -> String {
        do {
            try await fetchRecaptchaClient(siteKey: siteKey)
            if (recaptchaClient != nil) {
                do {
                    let token = try await recaptchaClient!.execute(
                        withAction: action, withTimeout: timeout)
                    if debug {
                        logger.logReCaptchaToken(token: token)
                    }

                    return token
                } catch let error as RecaptchaError {
                    throw error
                }
            }
        } catch let error as RecaptchaError {
            throw error
        }

        return ""
    }
}
