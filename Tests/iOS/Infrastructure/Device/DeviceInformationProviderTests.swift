//------------------------------------------------------------------------------
//  File:          DeviceInformationProviderTests.swift
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
import UIKit

@testable import BreadPartners

@Suite
@MainActor
struct DeviceInformationProviderTests {
    @Test
    func userAgentIncludesDeviceModelAndOperatingSystem() {
        let device = UIDevice.current

        #expect(
            DeviceInformationProvider.userAgent
                == "\(device.model): \(device.systemName) \(device.systemVersion)"
        )
    }
}
