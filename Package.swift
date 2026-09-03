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
            name: "BreadPartnersCoreTests",
            dependencies: ["BreadPartnersCore"],
            path: "Tests/Core"
        ),
        .testTarget(
            name: "BreadPartnersTests",
            dependencies: ["BreadPartners"],
            path: "Tests/iOS"
        ),
    ]
)
