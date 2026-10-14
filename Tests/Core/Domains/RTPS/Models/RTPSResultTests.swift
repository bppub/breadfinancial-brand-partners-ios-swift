//------------------------------------------------------------------------------
//  File:          RTPSResultTests.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Testing
@testable import BreadPartnersCore

@Suite struct RTPSResultTests {
    @Test(arguments: [
        ("0", RTPSResult.accountFound),
        ("01", RTPSResult.approved),
        ("10", RTPSResult.noHit),
        ("11", RTPSResult.makeOffer),
        ("12", RTPSResult.acknowledge),
        ("unknown", RTPSResult.noHit),
    ])
    func mapsReturnCodes(code: String, expected: RTPSResult) {
        #expect(RTPSResult(returnCode: code) == expected)
    }

    @Test
    func missingReturnCodeIsNoHit() {
        #expect(RTPSResult(returnCode: nil) == .noHit)
    }
}
