//------------------------------------------------------------------------------
//  File:          OptionalStringExtensionsTests.swift
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

@Suite struct OptionalStringExtensionsTests {
    @Test(
        "Filters missing or blank strings",
        arguments: [String?.none, "", " ", "\n\t"]
    )
    func filtersMissingOrBlankStrings(value: String?) {
        #expect(value.takeIfNotEmpty() == nil)
    }

    @Test(arguments: [String?("value"), "  value  ", "value\n"])
    func preservesNonblankString(value: String?) {
        #expect(value.takeIfNotEmpty() == value)
    }
}
