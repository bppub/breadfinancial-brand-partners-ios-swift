//------------------------------------------------------------------------------
//  File:          Package.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BreadPartners",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "BreadPartners",
            targets: ["BreadPartners"])
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.7.5"),
        .package(
            url:
                "https://github.com/GoogleCloudPlatform/recaptcha-enterprise-mobile-sdk.git",
            from: "18.9.1"),
    ],
    targets: [
        .target(
            name: "BreadPartnersCore",
            dependencies: []
        ),
        .target(
            name: "BreadPartnersTestSupport",
            dependencies: ["BreadPartnersCore"],
            path: "Tests/TestSupport",
            exclude: ["Tests"]
        ),
        .target(
            name: "BreadPartners",
            dependencies: [
                "BreadPartnersCore",
                "SwiftSoup",
                .product(
                    name: "RecaptchaEnterprise",
                    package: "recaptcha-enterprise-mobile-sdk"),
            ]
        ),
        .testTarget(
            name: "BreadPartnersTestSupportTests",
            dependencies: ["BreadPartnersCore", "BreadPartnersTestSupport"],
            path: "Tests/TestSupport/Tests"
        ),
        .testTarget(
            name: "BreadPartnersCoreTests",
            dependencies: ["BreadPartnersCore", "BreadPartnersTestSupport"],
            path: "Tests/Core"
        ),
        .testTarget(
            name: "BreadPartnersTests",
            dependencies: ["BreadPartners", "BreadPartnersTestSupport"],
            path: "Tests/iOS"
        ),
    ]
)
