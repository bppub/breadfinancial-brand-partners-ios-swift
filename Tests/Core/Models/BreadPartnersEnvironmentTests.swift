//------------------------------------------------------------------------------
//  File:          BreadPartnersEnvironmentTests.swift
//  Author(s):     Bread Financial
//  Date:          02 September 2026
//
//  Descriptions:  Unit tests for BreadPartnersEnvironment.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Testing
@testable import BreadPartnersCore

@Suite struct BreadPartnersEnvironmentTests {
    // MARK: - Raw Value Mapping

    @Test
    func testStageRawValue() {
        #expect(BreadPartnersEnvironment.stage.rawValue == "STAGE")
    }

    @Test
    func testProdRawValue() {
        #expect(BreadPartnersEnvironment.prod.rawValue == "PROD")
    }

    @Test
    func testUatRawValue() {
        #expect(BreadPartnersEnvironment.uat.rawValue == "UAT")
    }

    // MARK: - Initialisation from Raw Value

    @Test
    func testInitFromStage() {
        #expect(BreadPartnersEnvironment(rawValue: "STAGE") == .stage)
    }

    @Test
    func testInitFromProd() {
        #expect(BreadPartnersEnvironment(rawValue: "PROD") == .prod)
    }

    @Test
    func testInitFromUat() {
        #expect(BreadPartnersEnvironment(rawValue: "UAT") == .uat)
    }

    // MARK: - Invalid Raw Values

    @Test
    func testInitFromUnknownRawValue() {
        #expect(BreadPartnersEnvironment(rawValue: "UNKNOWN") == nil)
    }

    @Test
    func testInitFromEmptyString() {
        #expect(BreadPartnersEnvironment(rawValue: "") == nil)
    }

    @Test
    func testInitFromLowercaseRawValue() {
        #expect(BreadPartnersEnvironment(rawValue: "stage") == nil)
        #expect(BreadPartnersEnvironment(rawValue: "prod") == nil)
        #expect(BreadPartnersEnvironment(rawValue: "uat") == nil)
    }
}
