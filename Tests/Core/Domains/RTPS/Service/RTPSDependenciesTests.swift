//------------------------------------------------------------------------------
//  File:          RTPSDependenciesTests.swift
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
import Testing
@testable import BreadPartnersCore

@Suite struct RTPSDependenciesTests {
    @Test
    func storesInjectedDependencies() {
        let recaptcha = StubRecaptchaProvider()
        let requestBuilder = StubRTPSRequestBuilder()
        let responseDecoder = StubRTPSResponseDecoder()

        let dependencies = RTPSDependencies(
            recaptcha: recaptcha,
            requestBuilder: requestBuilder,
            responseDecoder: responseDecoder
        )

        #expect(dependencies.recaptcha is StubRecaptchaProvider)
        #expect(dependencies.requestBuilder is StubRTPSRequestBuilder)
        #expect(dependencies.responseDecoder is StubRTPSResponseDecoder)
    }
}
