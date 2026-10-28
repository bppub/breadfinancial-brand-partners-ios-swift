import BreadPartners
import SwiftUI

struct RTPSFormView: View {
    @StateObject private var viewModel = FormViewModel()
    @State private var formData = RTPSFormData()
    @State private var isExpanded: Bool = false

    var body: some View {
        Form {
            DisclosureGroup("Customer Info", isExpanded: $isExpanded) {
                TextField(
                    "First Name", text: $formData.firstName
                )
                TextField("Middle Initial", text: $formData.middleName)
                TextField("Last Name", text: $formData.lastName)
                TextField("Address 1", text: $formData.addressOne)
                TextField("Address 2", text: $formData.addressTwo)
                TextField("City", text: $formData.city)
                TextField("State", text: $formData.state)
                TextField("Zip Code", text: $formData.zip)
                TextField("Country", text: $formData.country)

                Picker("Location Type", selection: $formData.location) {
                    ForEach(RTPSFormData.locationTypes, id: \.self) { option in
                        Text(option.rawValue.capitalized).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())

                Picker("Financial Type", selection: $formData.financial) {
                    ForEach(RTPSFormData.financialType, id: \.self) { option in
                        Text(option.rawValue.capitalized).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())

                TextField("Prescreen ID", text: $formData.preScreenID)
                TextField("Email Address", text: $formData.email)
                TextField("Mobile Phone", text: $formData.mobile)
                TextField("Alternative Phone", text: $formData.alternateMobile)
                TextField("Card Amount", text: $formData.cardAmount)
                TextField("Card Tyoe", text: $formData.cardType)
                TextField("Store Number", text: $formData.storeNumber)
                TextField("Loyalty Number", text: $formData.loyaltyNumber)
                TextField("Customer Number", text: $formData.customerNumber)
                TextField("Product Amount", text: $formData.productAmount)
                TextField("Checkout Amount", text: $formData.checkoutAmount)
                TextField("Category", text: $formData.category)
                TextField("SKU", text: $formData.sku)
                TextField("Correlation Data", text: $formData.correlationData)
                TextField("Override Key", text: $formData.overrideKey)
                TextField("Card Choice Code", text: $formData.cardChoiceCode)
                TextField("Department ID", text: $formData.departmentId)
                Toggle(
                    "Existing Cardholder",
                    isOn: $formData.existing
                )
                Picker("Customer Accepted Offer", selection: $formData.customerAcceptedOffer) {
                    Text("Not Set").tag(nil as Bool?)
                    Text("True").tag(true as Bool?)
                    Text("False").tag(false as Bool?)
                }
                .pickerStyle(MenuPickerStyle())
                TextField("Cardholder Tier", text: $formData.cardholderTier)
                TextField("Channel", text: $formData.channel)
                TextField("Sub Channel", text: $formData.subchannel)
                TextField("Client Variable 1", text: $formData.clientVar1)
                TextField("Client Variable 2", text: $formData.clientVar2)
                TextField("Client Variable 3", text: $formData.clientVar3)
                TextField("Client Variable 4", text: $formData.clientVar4)
                Toggle(
                    "Allow Checkout",
                    isOn: $formData.allowCheckout
                )
                TextField("Selected Card Key", text: $formData.selectedCardKey)
                TextField(
                    "Default Selected Card Key",
                    text: $formData.defaultSelectedCardKey
                )
            }

            Picker("Mock Test Case", selection: $formData.mockTest) {
                ForEach(BreadPartnersMockOptions.allCases, id: \.self) {
                    option in
                    Text(
                        option == .noMock
                            ? "No Mock" : option.rawValue.capitalized
                    )
                    .tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())

            DisclosureGroup("EpJs Config") {
                Picker("SDK Env", selection: $formData.sdkEnv) {
                    ForEach(RTPSFormData.sdkEnvs, id: \.self) { option in
                        Text(option.rawValue.capitalized).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())

                TextField("API Key", text: $formData.apiKey)

                Toggle("Enable Logs", isOn: $formData.enableLog)
            }

            Section {
                Button(action: {
                    hideKeyboard()
                    viewModel.rtpsCall(formData: formData)
                }) {
                    Text("Test RTPS").frame(
                        maxWidth: .infinity, maxHeight: .infinity
                    )
                }
                .disabled(viewModel.isLoading)

                if let error = viewModel.error {
                    Section(header: Text("Error")) {
                        Text(error.localizedDescription)
                            .foregroundColor(.red)
                    }
                }

                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(
                            maxWidth: .infinity, maxHeight: .infinity
                        )
                }
            }
            
            
            
            Section {
                DisclosureGroup("Logs") {
                    if formData.enableLog {
                        Text(viewModel.logs).font(
                            .custom(
                                "Arial", size: 12
                            )
                        )
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }

        }.onChange(of: viewModel.overlayResponse) {
            _, newPopupView in
            guard let popup = newPopupView else { return }
            presentPopup(popup)
        }
        .onChange(of: formData) { _, _ in
            saveCachedFormData()
        }
        .onAppear {
            loadCachedFormData()
        }
        .onReceive(NotificationCenter.default.publisher(for: AppDataReset.didClear)) { _ in
            formData = RTPSFormData()
        }
    }

    // MARK: - Cache Methods

    private func saveCachedFormData() {
        formData.cache()
    }

    private func loadCachedFormData() {
        if let cachedData = RTPSFormData.loadCached() {
            formData = cachedData
        }
    }

    private func clearCachedFormData() {
        RTPSFormData.clearCache()
        formData = RTPSFormData()
    }
}
