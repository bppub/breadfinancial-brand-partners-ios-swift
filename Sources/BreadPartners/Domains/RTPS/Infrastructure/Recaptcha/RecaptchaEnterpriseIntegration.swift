//------------------------------------------------------------------------------
//  File:          RecaptchaEnterpriseIntegration.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import RecaptchaEnterprise

protocol RecaptchaClientProviding: Sendable {
    func execute(
        action: String,
        timeout: Double
    ) async throws -> String
}

protocol RecaptchaClientFactory: Sendable {
    func makeClient(siteKey: String) async throws -> (any RecaptchaClientProviding)?
}

// Live Recaptcha functionality must be tested via integration testing.

final class LiveRecaptchaClient: RecaptchaClientProviding, @unchecked Sendable {
    private let client: RecaptchaClient

    init(client: RecaptchaClient) {
        self.client = client
    }

    func execute(
        action: String,
        timeout: Double
    ) async throws -> String {
        try await client.execute(
            withAction: .init(customAction: action),
            withTimeout: timeout
        )
    }
}

struct LiveRecaptchaClientFactory: RecaptchaClientFactory {
    func makeClient(siteKey: String) async throws -> (any RecaptchaClientProviding)? {
        return LiveRecaptchaClient(
            client: try await Recaptcha.fetchClient(withSiteKey: siteKey)
        )
    }
}
