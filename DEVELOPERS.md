## Repository Development

Open `BreadPartners.xcworkspace` from the repository root as the primary Xcode entry point. It contains the Swift package, integration test app project, and UI test project, so SDK, app, and UI-test work can be done from one workspace.

- `BreadPartnersTestApp` launches the integration test app for manual validation; it is an app scheme, not an XCTest bundle.
- `BreadPartnersUITests` runs UI automation on an iOS Simulator.

The Swift package's XCTest schemes run from its generated workspace. Run Core unit tests on macOS with:

```sh
xcodebuild test -workspace .swiftpm/xcode/package.xcworkspace -scheme BreadPartnersCoreTests -destination 'platform=macOS'
```

Run the iOS SDK tests, including integration tests, on an iOS Simulator with:

```sh
xcodebuild test -workspace .swiftpm/xcode/package.xcworkspace -scheme BreadPartnersTests -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'
```

The UI tests can be run from the root workspace with the `BreadPartnersUITests` scheme. The Core suite uses macOS while the iOS and UI suites use an iOS Simulator.