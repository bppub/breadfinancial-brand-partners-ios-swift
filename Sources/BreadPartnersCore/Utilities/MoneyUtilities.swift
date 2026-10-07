//------------------------------------------------------------------------------
//  File:          MoneyUtilities.swift
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

/// Converts a monetary value in cents to dollars.
public func fromMoneyToDollars(_ moneyValue: Int64?) -> Double? {
    guard let moneyValue else { return nil }

    return Double(moneyValue) / 100.0
}
