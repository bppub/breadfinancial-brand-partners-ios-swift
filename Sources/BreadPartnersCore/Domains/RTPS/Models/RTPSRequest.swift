//------------------------------------------------------------------------------
//  File:          RTPSRequest.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

import Foundation

package struct RTPSRequest: Codable, Sendable {
    package let urlPath: String?
    package let firstName: String?
    package let lastName: String?
    package let address1: String?
    package let city: String?
    package let state: String?
    package let zip: String?
    package let storeNumber: String?
    package let location: String?
    package let channel: String?
    package let subchannel: String?
    package let reCaptchaToken: String?
    package let mockResponse: String?
    package let overrideConfig: OverrideConfig?
    package let prescreenId: String?
    package let customerAcceptedOffer: Bool?
    package let platform: String
    package let alternativePhone: String?
    package let mobilePhone: String?
    package let emailAddress: String?

    package struct OverrideConfig: Codable, Sendable, Equatable {
        package let enhancedPresentment: Bool?

        package init(enhancedPresentment: Bool?) {
            self.enhancedPresentment = enhancedPresentment
        }
    }

    package init(
        urlPath: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        address1: String? = nil,
        city: String? = nil,
        state: String? = nil,
        zip: String? = nil,
        storeNumber: String? = nil,
        location: String? = nil,
        channel: String? = nil,
        subchannel: String? = nil,
        reCaptchaToken: String? = nil,
        mockResponse: String? = nil,
        overrideConfig: OverrideConfig? = nil,
        prescreenId: String? = nil,
        customerAcceptedOffer: Bool? = nil,
        mobilePhone: String? = nil,
        emailAddress: String? = nil,
        alternativePhone: String? = nil
    ) {
        self.urlPath = urlPath
        self.firstName = firstName
        self.lastName = lastName
        self.address1 = address1
        self.city = city
        self.state = state
        self.zip = zip
        self.storeNumber = storeNumber ?? CoreDefaults.defaultStoreNumber
        self.location = location
        self.channel = channel
        self.subchannel = subchannel
        self.reCaptchaToken = reCaptchaToken
        self.mockResponse = mockResponse
        self.overrideConfig = overrideConfig
        self.prescreenId = prescreenId
        self.customerAcceptedOffer = customerAcceptedOffer
        self.platform = "ios"
        self.emailAddress = emailAddress
        self.mobilePhone = mobilePhone
        self.alternativePhone = alternativePhone
    }
}
