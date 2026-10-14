//------------------------------------------------------------------------------
//  File:          BreadPartnersEnvironment.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

/// Represents the different environments the SDK can operate in.
///
/// - `stage`: Use this environment for testing and development.
/// - `prod`: **Default** Use this environment for production.
public enum BreadPartnersEnvironment: String, CaseIterable, Sendable {
    case stage = "STAGE"
    case prod = "PROD"
    case uat = "UAT"
}
