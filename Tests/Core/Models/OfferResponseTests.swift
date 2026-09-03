//------------------------------------------------------------------------------
//  File:          OfferResponseTests.swift
//  Author(s):     Bread Financial
//  Date:          02 September 2026
//
//  Descriptions:  Unit tests for OfferResponse.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Testing
@testable import BreadPartnersCore

@Suite struct OfferResponseTests {
    @Test
    func rawValues() {
        #expect(OfferResponse.yes.rawValue == "YES")
        #expect(OfferResponse.no.rawValue == "NO")
        #expect(OfferResponse.notMe.rawValue == "NOT_ME")
        #expect(OfferResponse.abandoned.rawValue == "ABANDONED")
        #expect(OfferResponse.prescreenNo.rawValue == "PRESCREEN_NO")
    }

    @Test(arguments: ["YES", "NO", "NOT_ME", "ABANDONED", "PRESCREEN_NO"])
    func initFromRawValue(rawValue: String) throws {
        let response = try #require(OfferResponse(rawValue: rawValue))
        #expect(response.rawValue == rawValue)
    }

    @Test(arguments: ["UNKNOWN", "", "yes", "no", "not_me", "abandoned", "prescreen_no"])
    func invalidRawValue(rawValue: String) {
        #expect(OfferResponse(rawValue: rawValue) == nil)
    }
}
