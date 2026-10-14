//------------------------------------------------------------------------------
//  File:          ContentView.swift
//  Author(s):     Bread Financial
//
//  Description:   Main screen of the test app. Provides buttons to initialize
//                 the SDK, register a text placement, and open a popup
//                 experience. Replace the sample integration key and placement
//                 identifiers with values provided for your brand.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import SwiftUI
import BreadPartners

struct ContentView: View {

    // MARK: - Configuration
    // Replace these values with the ones provided for your brand.
    private let integrationKey = "REPLACE_WITH_YOUR_INTEGRATION_KEY"
    private let placementId = "03d69ff1-f90c-41b2-8a27-836af7f1eb98"

    // MARK: - State
    @State private var isSetUp = false
    @State private var statusMessage = "SDK not initialized. Tap \"Setup SDK\" to begin."
    @State private var placementText: BreadPartnerLinkTextSwitUI?
    @State private var eventLog: [String] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button("1. Setup SDK") {
                        Task { await setupSDK() }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("2. Register Placement") {
                        Task { await registerPlacement() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(!isSetUp)

                    Button("3. Open Popup Experience") {
                        Task { await openExperience() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(!isSetUp)

                    if let placementText {
                        Divider()
                        Text("Rendered placement:")
                            .font(.headline)
                        placementText
                            .foregroundStyle(.gray)
                            .font(.custom("Helvetica", size: 16))
                    }

                    if !eventLog.isEmpty {
                        Divider()
                        Text("Event log:")
                            .font(.headline)
                        ForEach(Array(eventLog.enumerated()), id: \.offset) { _, line in
                            Text("• \(line)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("BreadPartners Test App")
        }
    }

    // MARK: - SDK Interactions

    private func setupSDK() async {
        await BreadPartnersSDK.shared.setup(
            environment: .stage,
            integrationKey: integrationKey,
            enableLog: true
        )
        isSetUp = true
        statusMessage = "SDK initialized (stage environment)."
    }

    private func registerPlacement() async {
        await BreadPartnersSDK.shared.registerPlacements(
            merchantConfiguration: makeMerchantConfiguration(),
            placementsConfiguration: makePlacementConfiguration(),
            splitTextAndAction: false,
            forSwiftUI: true
        ) { event in
            Task { @MainActor in
                handle(event)
            }
        }
    }

    private func openExperience() async {
        await BreadPartnersSDK.shared.openExperienceForPlacement(
            merchantConfiguration: makeMerchantConfiguration(),
            placementsConfiguration: makePlacementConfiguration(),
            forSwiftUI: true
        ) { event in
            Task { @MainActor in
                handle(event)
            }
        }
    }

    @MainActor
    private func handle(_ event: BreadPartnerEvents) {
        switch event {
        case .renderSwiftUITextViewWithLink(let textView):
            placementText = textView
            log("renderSwiftUITextViewWithLink")
        case .textClicked:
            log("textClicked")
        case .actionButtonTapped:
            log("actionButtonTapped")
        case .screenName(let name):
            log("screenName: \(name)")
        case .popupClosed:
            log("popupClosed")
        case .sdkError(let error):
            log("sdkError: \(error.localizedDescription)")
        default:
            log("\(event)")
        }
    }

    private func log(_ message: String) {
        eventLog.append(message)
    }

    // MARK: - Sample Data

    private func makeMerchantConfiguration() -> MerchantConfiguration {
        MerchantConfiguration(
            buyer: BreadPartnersBuyer(
                givenName: "Jack",
                familyName: "Seamus",
                additionalName: "C.",
                birthDate: "1974-08-21",
                email: "johncseamus@gmail.com",
                phone: "+13235323423",
                billingAddress: BreadPartnersAddress(
                    address1: "323 something lane",
                    address2: "apt. B",
                    country: "USA",
                    locality: "NYC",
                    region: "NY",
                    postalCode: "11222"
                ),
                shippingAddress: nil
            ),
            loyaltyID: "xxxxxx",
            storeNumber: "1234567",
            channel: "P",
            subchannel: "X"
        )
    }

    private func makePlacementConfiguration() -> PlacementConfiguration {
        let placementData = PlacementData(
            financingType: .installments,
            locationType: .category,
            placementId: placementId,
            domID: "123",
            order: Order(
                subTotal: CurrencyValue(currency: "USD", value: 0),
                totalDiscounts: CurrencyValue(currency: "USD", value: 0),
                totalPrice: CurrencyValue(currency: "USD", value: 73900),
                totalShipping: CurrencyValue(currency: "USD", value: 0),
                totalTax: CurrencyValue(currency: "USD", value: 0),
                discountCode: "string",
                pickupInformation: nil,
                fulfillmentType: .delivery,
                items: []
            )
        )
        return PlacementConfiguration(placementData: placementData)
    }
}

#Preview {
    ContentView()
}
