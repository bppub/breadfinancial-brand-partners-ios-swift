// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BreadPartnersSDK",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "BreadPartnersSDK",
            targets: ["BreadPartnersSDK"])
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
            name: "BreadPartnersSDKCore",
            dependencies: []
        ),
        .target(
            name: "BreadPartnersSDK",
            dependencies: [
                "BreadPartnersSDKCore",
                "SwiftSoup",
                .product(
                    name: "RecaptchaEnterprise",
                    package: "recaptcha-enterprise-mobile-sdk"),
            ]
        ),
        .testTarget(
            name: "BreadPartnersSDKCoreTests",
            dependencies: ["BreadPartnersSDKCore"],
            path: "Tests/Core"
        ),
        .testTarget(
            name: "BreadPartnersSDKTests",
            dependencies: ["BreadPartnersSDK"],
            path: "Tests/SDK"
        ),
    ]
)
