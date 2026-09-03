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

/// Enum representing the results of a prescreen check in RTPS flow.
enum PrescreenResult {
    case accountFound
    // Has been pre-approved
    case approved
    case noHit
    // Not pre-approved but should / could apply
    case makeOffer
    case acknowledge
}

/// Mapping of return codes to corresponding PrescreenResult.
let prescreenResultMap: [String: PrescreenResult] = [
    "0": .accountFound,
    "01": .approved,
    "10": .noHit,
    "11": .makeOffer,
    "12": .acknowledge,
]

/// Returns the corresponding PrescreenResult based on the given API response string.
func getPrescreenResult(from apiResponse: String) -> PrescreenResult {
    return prescreenResultMap[apiResponse] ?? .noHit
}

/// Represents the response model for an RTPS.
struct RTPSResponse: Codable {
    let returnCode: String?
    let prescreenId: Int64?
    let firstName: String?
    let middleInitial: String?
    let lastName: String?
    let address1: String?
    let address2: String?
    let city: String?
    let state: String?
    let zip: String?
    let cardType: String?
    let isExpired: Bool?
    let hasExistingAccount: Bool?
    let errorMessage: String?
    let errorCode: Int?

    enum CodingKeys: String, CodingKey {
        case returnCode
        case prescreenId
        case firstName
        case middleInitial
        case lastName
        case address1
        case address2
        case city
        case state
        case zip
        case cardType
        case isExpired
        case hasExistingAccount
        case errorMessage
        case errorCode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle prescreenId as Int64
        prescreenId = try container.decodeIfPresent(Int64.self, forKey: .prescreenId)

        // Handle returnCode as either String or Int, convert to String
        if let returnCodeString = try? container.decode(String.self, forKey: .returnCode) {
            returnCode = returnCodeString
        } else if let returnCodeInt = try? container.decode(Int.self, forKey: .returnCode) {
            returnCode = String(returnCodeInt)
        } else {
            returnCode = nil
        }

        // Decode remaining fields
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
}
