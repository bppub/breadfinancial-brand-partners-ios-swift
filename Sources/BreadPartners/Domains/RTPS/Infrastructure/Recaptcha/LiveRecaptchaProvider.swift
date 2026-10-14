//------------------------------------------------------------------------------
//  File:          LiveRecaptchaProvider.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import BreadPartnersCore

package actor LiveRecaptchaProvider: RecaptchaProviding {
    private let logger: Logger
    private let clientFactory: any RecaptchaClientFactory
    private var recaptchaClient: (any RecaptchaClientProviding)?

    internal init(
        logger: Logger = Logger(),
        clientFactory: any RecaptchaClientFactory = LiveRecaptchaClientFactory()
    ) {
        self.logger = logger
        self.clientFactory = clientFactory
    }

    package func execute(
        siteKey: String,
        action: String,
        timeout: Double,
        debug: Bool
    ) async throws -> String {
        if recaptchaClient == nil {
            recaptchaClient = try await clientFactory.makeClient(siteKey: siteKey)
        }

        guard let recaptchaClient else {
            return ""
        }

        let token = try await recaptchaClient.execute(
            action: action,
            timeout: timeout
        )

        if debug {
            logger.logReCaptchaToken(token: token)
        }

        return token
    }
}
