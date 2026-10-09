# Repository AI Instructions

## Swift File Headers

Always include the standard Bread Financial copyright header in every newly generated Swift file under `Sources/` or `Tests/`. Keep it at the top of the file, use the actual filename, and preserve the field order and wording below:

```swift
//------------------------------------------------------------------------------
//  File:          {FileName}.swift
//  Author(s):     Bread Financial
//  Date:          {Date}
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © {Year} Bread Financial
//------------------------------------------------------------------------------
```

Until the refactor project is explicitly complete, use `31 October 2026` for `{Date}` in every new Swift header, even if the file is created later. Do not substitute the current date. Use `2026` for `{Year}`. Keep these values identical across the repository unless the user explicitly changes this policy. For `Package.swift`, keep `// swift-tools-version: 6.0` as the first line and place the copyright header immediately after it.

## Target Architecture

- `BreadPartnersCore` contains reusable Swift/Foundation domain and infrastructure code: models, business rules, services, networking abstractions, and HTML parsing. It is built and tested on macOS as well as used by the iOS target. Keep UIKit, SwiftUI, WebKit, device-specific behavior, and other iOS-only dependencies out of Core. SwiftSoup is an existing Core dependency for HTML parsing.
- `BreadPartners` is the iOS integration layer. It owns UI and platform-specific implementations, SDK composition, device integrations, and adapters that connect those implementations to Core services. It depends on `BreadPartnersCore` and iOS-specific dependencies such as Recaptcha.
- Put platform-independent behavior in Core and keep UI, simulator, and device concerns in BreadPartners. Test Core changes with the macOS Core scheme; test iOS integration and UI changes with the iOS Simulator scheme.
- When a type or member must be used by another target in this package, mark it `package`. Do not assume a synthesized memberwise initializer has package visibility; add an explicit `package init` when cross-target construction is needed.

## CI Validation

Run commands from the repository root. These are the checks used by `.github/workflows/ci.yml`; use Xcode schemes rather than substituting `swift test` for package validation.

```sh
Scripts/format.sh --check
Scripts/lint.sh

xcodebuild test \
  -scheme BreadPartnersTestSupportTests \
  -destination 'platform=macOS' \
  -resultBundlePath TestSupportResults.xcresult \
  -enableCodeCoverage YES \
  CODE_SIGNING_ALLOWED=NO

xcodebuild test \
  -scheme BreadPartnersCoreTests \
  -destination 'platform=macOS' \
  -resultBundlePath CoreTestResults.xcresult \
  -enableCodeCoverage YES \
  CODE_SIGNING_ALLOWED=NO

xcodebuild test \
  -scheme BreadPartnersTests \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  -resultBundlePath iOSTestResults.xcresult \
  -enableCodeCoverage YES \
  CODE_SIGNING_ALLOWED=NO

xcodebuild \
  -scheme BreadPartners \
  -destination 'generic/platform=iOS' \
  -sdk iphoneos \
  -verbose \
  CODE_SIGNING_ALLOWED=NO \
  build
```

`swift test` will fail due to iOS import dependencies such as RecaptchaEnterpriseSDK. Always use the appropriate`xcodebuild` with the appropriate scheme and destination for iOS tests.

Use the `BreadPartners` scheme if the entire repository needs to be validated at once.

```sh
xcodebuild test \
  -scheme BreadPartners \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  -enableCodeCoverage YES \
  CODE_SIGNING_ALLOWED=NO
```