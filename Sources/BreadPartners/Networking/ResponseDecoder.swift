//------------------------------------------------------------------------------
//  File:          ResponseDecoder.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import BreadPartnersCore
import Foundation

internal enum ResponseDecoder {
    static func decode<T: Decodable>(_ response: Any, as type: T.Type) throws -> T {
        let payload = (response as? AnySendable)?.value ?? response
        return try BreadPartnersCore.decodeJSON(from: payload, to: type)
    }
}
