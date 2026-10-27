//------------------------------------------------------------------------------
//  File:          Fixtures.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing canned JSON payloads for the endpoints exercised by UI tests.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Foundation

/// Canned JSON payloads for the endpoints exercised by UI tests.
///
/// Replace the placeholder bodies with captured real responses to render actual
/// placement content. The brand-config stub is required for *every* test because
/// `BreadPartnersSDK.setup` fetches it before any other call.
enum Fixtures {

    enum Brand {
        /// Minimal brand config returned from `/brands/{id}/config`.
        static let config = MockHttpResponse(
            match: "/config",
            jsonString: #"{ "brandId": "test-brand", "config": {} }"#
        )

        /// Minimal brand style returned from `/brands/{id}/style`.
        static let style = MockHttpResponse(
            match: "/style",
            jsonString: #"{ "style": {} }"#
        )
    }

    enum Placements {
        /// Text placement returned from `/generatePlacements`.
        static let pala = MockHttpResponse(match: "/generatePlacements", fixture: "pala-placement")
    }
}
