//------------------------------------------------------------------------------
//  File:          APIBaseURLsLaunchOverrideTests.swift
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

@Suite
struct APIBaseURLsLaunchOverrideTests {
    @Test
    func returnsNilWhenKeyIsMissing() {
        #expect(APIBaseURLs.launchOverride(environment: [:]) == nil)
    }
    #if DEBUG
        @Test(arguments: ["http://localhost:8080", "http://127.0.0.1:8080/"])
        func acceptsLoopbackURLs(value: String) {
            let expectedBase = value.hasSuffix("/") ? String(value.dropLast()) : value

            #expect(
                APIBaseURLs.launchOverride(environment: [APIBaseURLs.launchOverrideKey: value])
                    == APIBaseURLs(brands: expectedBase, rtps: expectedBase)
            )
        }
    #else
        @Test(arguments: ["http://localhost:8080", "http://127.0.0.1:8080/"])
        func ignoresLoopbackOverrideInRelease(value: String) {
            #expect(APIBaseURLs.launchOverride(environment: [APIBaseURLs.launchOverrideKey: value]) == nil)
        }
    #endif
}
