//------------------------------------------------------------------------------
//  File:          RTPSDependencies.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

package struct RTPSDependencies: Sendable {
    package let recaptcha: any RecaptchaProviding
    package let requestBuilder: any RTPSRequestBuilding
    package let responseDecoder: any RTPSResponseDecoding

    package init(
        recaptcha: any RecaptchaProviding,
        requestBuilder: any RTPSRequestBuilding,
        responseDecoder: any RTPSResponseDecoding
    ) {
        self.recaptcha = recaptcha
        self.requestBuilder = requestBuilder
        self.responseDecoder = responseDecoder
    }
}
