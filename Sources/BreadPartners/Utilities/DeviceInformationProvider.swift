//------------------------------------------------------------------------------
//  File:          DeviceInformationProvider.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import UIKit

@MainActor internal enum DeviceInformationProvider {
    static var userAgent: String {
        let device = UIDevice.current
        return "\(device.model): \(device.systemName) \(device.systemVersion)"
    }
}
