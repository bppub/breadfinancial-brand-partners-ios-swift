//------------------------------------------------------------------------------
//  File:          RTPSResponse.swift
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

package struct RTPSResponse: Codable, Sendable {
    package let returnCode: String?
    package let prescreenId: Int64?
    package let firstName: String?
    package let middleInitial: String?
    package let lastName: String?
    package let address1: String?
    package let address2: String?
    package let city: String?
    package let state: String?
    package let zip: String?
    package let cardType: String?
    package let isExpired: Bool?
    package let hasExistingAccount: Bool?
    package let errorMessage: String?
    package let errorCode: Int?

    package init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        prescreenId = try container.decodeIfPresent(Int64.self, forKey: .prescreenId)

        if let value = try? container.decode(String.self, forKey: .returnCode) {
            returnCode = value
        } else if let value = try? container.decode(Int.self, forKey: .returnCode) {
            returnCode = String(value)
        } else {
            returnCode = nil
        }

        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        middleInitial = try container.decodeIfPresent(String.self, forKey: .middleInitial)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        address1 = try container.decodeIfPresent(String.self, forKey: .address1)
        address2 = try container.decodeIfPresent(String.self, forKey: .address2)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        state = try container.decodeIfPresent(String.self, forKey: .state)
        zip = try container.decodeIfPresent(String.self, forKey: .zip)
        cardType = try container.decodeIfPresent(String.self, forKey: .cardType)
        isExpired = try container.decodeIfPresent(Bool.self, forKey: .isExpired)
        hasExistingAccount = try container.decodeIfPresent(Bool.self, forKey: .hasExistingAccount)
        errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
        errorCode = try container.decodeIfPresent(Int.self, forKey: .errorCode)
    }

    private enum CodingKeys: String, CodingKey {
        case returnCode, prescreenId, firstName, middleInitial, lastName
        case address1, address2, city, state, zip, cardType
        case isExpired, hasExistingAccount, errorMessage, errorCode
    }
}
