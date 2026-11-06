//------------------------------------------------------------------------------
//  File:          JSONUtilitiesTests.swift
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

@Suite struct JSONUtilitiesTests {
    private struct TestValue: Codable, Equatable {
        let id: Int
        let name: String
    }

    @Test
    func removesNilValuesAndNormalizesNestedDoubles() throws {
        let input: [String: Any?] = [
            "missing": nil,
            "amount": 1.236,
            "nested": ["amount": 9.999, "missing": nil] as [String: Any?],
        ]
        let output = try #require(unwrapForJSON(input) as? [String: Any])
        let nested = try #require(output["nested"] as? [String: Any])

        #expect(output["missing"] == nil)
        #expect(output["amount"] as? Double == 1.24)
        #expect(nested["missing"] == nil)
        #expect(nested["amount"] as? Double == 10.0)
    }

    @Test
    func stringifiesJSONWithSortedKeys() {
        let input: [String: Any?] = ["z": 1, "a": "first", "missing": nil]

        #expect(stringifyJSON(input) == "{\n  \"a\" : \"first\",\n  \"z\" : 1\n}")
    }

    @Test
    func stringifyJSONReturnsEmptyStringForUnsupportedValue() {
        #expect(stringifyJSON(["invalid": Double.nan]) == "")
    }
}
