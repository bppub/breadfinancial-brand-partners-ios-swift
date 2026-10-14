import BreadPartners
import SwiftUI

// Wrapper to make Item identifiable with stable UUID
struct IdentifiableItem: Identifiable {
  let id = UUID()
  var item: Item
}

struct PlacementFormView: View {
  @StateObject private var viewModel = FormViewModel()
  @State private var formData = PlacementFormData()
  @State private var isExpanded: Bool = false

  @State private var isLoading = false
  @State private var error: String? = nil
  @State private var saveTimer: Timer?
  @State private var identifiableItems: [IdentifiableItem] = []

  var body: some View {
    Form {
      DisclosureGroup("Placement Info", isExpanded: $isExpanded) {
        TextField(
          "Placement ID", text: $formData.placementId
        )
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        
        TextField("Total Price", text: $formData.totalPrice)
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
          
        Picker("No Action", selection: $formData.noAction) {
            Text("False").tag(false)
            Text("True").tag(true)
        }
        .pickerStyle(MenuPickerStyle())
          
        TextField("Loyalty ID", text: $formData.loyaltyId)
        TextField("Campaign ID", text: $formData.campaignID)
        TextField("Store Number", text: $formData.storeNumber)
        TextField("Override Key", text: $formData.overrideKey)
        TextField("Department ID", text: $formData.departmentId)
        TextField("Prequal Credit Limit", text: $formData.prequalCreditLimit)
          .keyboardType(.numberPad)
        TextField("Prequalification ID", text: $formData.prequalificationId)
        TextField("Financing Buyer ID", text: $formData.financingBuyerId)
        TextField("InSession Token", text: $formData.inSessionToken)
      }

      DisclosureGroup("Cardholder Info") {
        TextField(
          "Cardholder Tier", text: $formData.cardholderTier
        )
        TextField("Channel", text: $formData.channel)
        TextField("Sub Channel", text: $formData.subchannel)
        TextField(
          "Client Variable 1", text: $formData.clientVar1
        )
        TextField(
          "Client Variable 2", text: $formData.clientVar2
        )
        TextField(
          "Client Variable 3", text: $formData.clientVar3
        )
        TextField(
          "Client Variable 4", text: $formData.clientVar4
        )
        
        DisclosureGroup("Buyer Information") {
          // Buyer Name Fields
          TextField("Buyer First Name", text: $formData.buyerGivenName)
          TextField("Buyer Last Name", text: $formData.buyerFamilyName)
          TextField("Buyer Middle Name", text: $formData.buyerAdditionalName)
          TextField("Buyer Birth Date", text: $formData.buyerBirthDate)
            .textInputAutocapitalization(.never)
          
          // Buyer Contact Fields
          TextField("Buyer Email", text: $formData.buyerEmail)
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
          TextField("Buyer Phone", text: $formData.buyerPhone)
            .keyboardType(.phonePad)
          TextField("Buyer Alternative Phone", text: $formData.buyerAlternativePhone)
            .keyboardType(.phonePad)
          
          // Billing Address
          DisclosureGroup("Billing Address") {
            TextField("Billing Address 1", text: $formData.billingAddress1)
            TextField("Billing Address 2", text: $formData.billingAddress2)
            TextField("Billing City", text: $formData.billingLocality)
            TextField("Billing State", text: $formData.billingRegion)
            TextField("Billing Zip Code", text: $formData.billingPostalCode)
              .keyboardType(.numberPad)
            TextField("Billing Country", text: $formData.billingCountry)
          }
          
          // Shipping Address
          DisclosureGroup("Shipping Address") {
            TextField("Shipping Address 1", text: $formData.shippingAddress1)
            TextField("Shipping Address 2", text: $formData.shippingAddress2)
            TextField("Shipping City", text: $formData.shippingLocality)
            TextField("Shipping State", text: $formData.shippingRegion)
            TextField("Shipping Zip Code", text: $formData.shippingPostalCode)
              .keyboardType(.numberPad)
            TextField("Shipping Country", text: $formData.shippingCountry)
          }
        }
      }

      DisclosureGroup("Checkout Settings") {
        Toggle("Allow Checkout", isOn: $formData.allowCheckout)
        TextField(
          "Selected Card Key", text: $formData.selectedCardKey
        )
        TextField(
          "Default Selected Card Key",
          text: $formData.defaultSelectedCardKey
        )
        TextField("Account ID", text: $formData.accountId)
        TextField(
          "Application ID", text: $formData.applicationId
        )
        TextField(
          "Invoice Number", text: $formData.invoiceNumber
        )

        TextField(
          "Total Price", text: $formData.totalPrice
        )
        TextField(
          "Sub Total", text: $formData.subTotal
        )
        TextField(
          "Total Tax", text: $formData.totalTax
        )
        TextField(
          "Total Discount", text: $formData.totalDiscount
        )
        TextField(
          "Total Shipping", text: $formData.totalShipping
        )

        DisclosureGroup("Items") {
          ItemsSectionWithIdentifiers(
            identifiableItems: $identifiableItems,
            onChange: scheduleSave
          )
        }

        Picker("Payment Mode", selection: $formData.paymentMode) {
          ForEach(PlacementFormData.paymentModes, id: \.self) {
            Text($0)
          }
        }
        TextField(
          "Provider Config", text: $formData.providerConfig
        )
        Toggle(
          "Skip Verification",
          isOn: $formData.skipVerification
        )
        
        TextField(
          "Discount Code", text: $formData.discountCode
        )
        Toggle(
          "BNPL Eligible",
          isOn: $formData.bnplEligible
        )

        Picker("Fulfillment Type", selection: $formData.fulfillmentType) {
          ForEach([OrderFulfillmentType.pickup, .delivery, .multiple, .unknown], id: \.self) { option in
            Text(option.rawValue.capitalized).tag(option as OrderFulfillmentType?)
          }
        }
        .pickerStyle(MenuPickerStyle())
        
        DisclosureGroup("Pickup Information") {
          TextField("Pickup First Name", text: $formData.pickupGivenName)
          TextField("Pickup Last Name", text: $formData.pickupFamilyName)
          TextField("Pickup Middle Name", text: $formData.pickupAdditionalName)
          TextField("Pickup Phone", text: $formData.pickupPhone)
          TextField("Pickup Email", text: $formData.pickupEmail)
          TextField("Pickup Address 1", text: $formData.pickupAddress1)
          TextField("Pickup Address 2", text: $formData.pickupAddress2)
          TextField("Pickup City", text: $formData.pickupLocality)
          TextField("Pickup State", text: $formData.pickupRegion)
          TextField("Pickup Zip Code", text: $formData.pickupPostalCode)
          TextField("Pickup Country", text: $formData.pickupCountry)
        }
      }

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

      DisclosureGroup("Placement Style") {
        DynamicFonts(formData: $formData)

        DynamicColors(formData: $formData)

        Toggle(
          "Separate Link & Button",
          isOn: $formData.separateTextAndButton
        ).padding(
          EdgeInsets(
            top: 5, leading: 0, bottom: 10, trailing: 0
          ))
      }

      DisclosureGroup("Popup Styling") {
        DynamicPopupStyles(formData: $formData)
      }

      Section {
        Button(action: {
          hideKeyboard()
          viewModel.generatePlacements(formData: formData) { prequalCreditLimit, prequalificationId, financingBuyerId, inSessionToken in
            // Update formData with values from UNIFIED_OFFERS_RECEIVED event
            formData.prequalCreditLimit = prequalCreditLimit
            formData.prequalificationId = prequalificationId
            formData.financingBuyerId = financingBuyerId
            formData.inSessionToken = inSessionToken
            scheduleSave()
          }
        }) {
          Text("Generate Placement").frame(
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

        } else {
          if let textWithLinkResponse = viewModel.textWithLinkResponse {
              if formData.noAction {
                  // No Action: display as-is without any formatting to preserve SDK's default behavior
                  textWithLinkResponse
              } else {
                  textWithLinkResponse
                    .linkColor(formData.secondaryColor)
                    .linkFont(
                      formData.fontName,
                      fontSize: formData.fontSize
                    )
                    .font(
                      .custom(
                        formData.fontName,
                        size: formData.fontSize
                      )
                    )
                    .foregroundStyle(formData.primaryColor)
                    .bold()
              }
          }
          if let textWithButton = viewModel.textWithButton {
            textWithButton.0
              .textColor(formData.primaryColor)
              .font(
                .custom(
                  formData.fontName,
                  size: formData.fontSize
                ))

            textWithButton.1
              .font(
                .custom(
                  formData.fontName,
                  size: formData.fontSize
                )
              )
              .textColor(Color.white)
              .backgroundColor(Color.blue)
              .cornerRadius(8)
              .alignment(.trailing)
          }
        }
      }

      Section {
        Button(action: {
          hideKeyboard()
          viewModel.openExperienceForPlacement(formData: formData) { prequalCreditLimit, prequalificationId, financingBuyerId, inSessionToken in
            // Update formData with values from UNIFIED_OFFERS_RECEIVED event
            formData.prequalCreditLimit = prequalCreditLimit
            formData.prequalificationId = prequalificationId
            formData.financingBuyerId = financingBuyerId
            formData.inSessionToken = inSessionToken
            scheduleSave()
          }
        }) {
          Text("Open Experience for Placement").frame(
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

        } else {
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

    }
    .onAppear {
      loadCachedData()
    }
    .onDisappear {
      saveTimer?.invalidate()
      saveFormData()
    }
    .modifier(PlacementInfoChangeModifier(formData: formData, onSave: scheduleSave))
    .modifier(CardholderInfoChangeModifier(formData: formData, onSave: scheduleSave))
    .modifier(CheckoutSettingsChangeModifier(formData: formData, onSave: scheduleSave))
    .modifier(ConfigChangeModifier(formData: formData, onSave: scheduleSave))
    .onChange(of: viewModel.overlayResponse) { _, newPopupView in
      handleOverlayResponse(newPopupView)
    }
  }

  // MARK: - Helper Methods

  private func loadCachedData() {
    if let cachedData = PreferencesManager.shared.loadPlacementFormData() {
      formData = cachedData
      identifiableItems = formData.items.map { IdentifiableItem(item: $0) }
    }
  }

  private func scheduleSave() {
    // Cancel existing timer
    saveTimer?.invalidate()

    // Schedule new save after 0.5 second delay (debounced)
    saveTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
      saveFormData()
    }
  }

  private func saveFormData() {
    formData.items = identifiableItems.map { $0.item }
    PreferencesManager.shared.savePlacementFormData(formData)
  }

  private func handleOverlayResponse(_ newPopupView: UIViewController?) {
    guard let popup = newPopupView else { return }
    presentPopup(popup)
  }
}

// MARK: - Placement Info Change Modifier
struct PlacementInfoChangeModifier: ViewModifier {
  let formData: PlacementFormData
  let onSave: () -> Void

  func body(content: Content) -> some View {
    content
      .onChange(of: formData.placementId) { _, _ in onSave() }
      .onChange(of: formData.totalPrice) { _, _ in onSave() }
      .onChange(of: formData.location) { _, _ in onSave() }
      .onChange(of: formData.financial) { _, _ in onSave() }
      .onChange(of: formData.noAction) { _, _ in onSave() }
      .onChange(of: formData.loyaltyId) { _, _ in onSave() }
      .onChange(of: formData.campaignID) { _, _ in onSave() }
      .onChange(of: formData.storeNumber) { _, _ in onSave() }
      .onChange(of: formData.overrideKey) { _, _ in onSave() }
      .onChange(of: formData.departmentId) { _, _ in onSave() }
  }
}

// MARK: - Cardholder Info Change Modifier
struct CardholderInfoChangeModifier: ViewModifier {
  let formData: PlacementFormData
  let onSave: () -> Void

  func body(content: Content) -> some View {
    content
      .onChange(of: formData.cardholderTier) { _, _ in onSave() }
      .onChange(of: formData.channel) { _, _ in onSave() }
      .onChange(of: formData.subchannel) { _, _ in onSave() }
      .onChange(of: formData.clientVar1) { _, _ in onSave() }
      .onChange(of: formData.clientVar2) { _, _ in onSave() }
      .onChange(of: formData.clientVar3) { _, _ in onSave() }
      .onChange(of: formData.clientVar4) { _, _ in onSave() }
  }
}

// MARK: - Checkout Settings Change Modifier
struct CheckoutSettingsChangeModifier: ViewModifier {
  let formData: PlacementFormData
  let onSave: () -> Void

  func body(content: Content) -> some View {
    content
      .onChange(of: formData.allowCheckout) { _, _ in onSave() }
      .onChange(of: formData.selectedCardKey) { _, _ in onSave() }
      .onChange(of: formData.defaultSelectedCardKey) { _, _ in onSave() }
      .onChange(of: formData.accountId) { _, _ in onSave() }
      .onChange(of: formData.applicationId) { _, _ in onSave() }
      .onChange(of: formData.invoiceNumber) { _, _ in onSave() }
      .onChange(of: formData.subTotal) { _, _ in onSave() }
      .onChange(of: formData.totalTax) { _, _ in onSave() }
      .onChange(of: formData.totalDiscount) { _, _ in onSave() }
      .onChange(of: formData.totalShipping) { _, _ in onSave() }
      .onChange(of: formData.paymentMode) { _, _ in onSave() }
      .onChange(of: formData.providerConfig) { _, _ in onSave() }
      .onChange(of: formData.skipVerification) { _, _ in onSave() }
      .onChange(of: formData.items.count) { _, _ in onSave() }
  }
}

// MARK: - Config Change Modifier
struct ConfigChangeModifier: ViewModifier {
  let formData: PlacementFormData
  let onSave: () -> Void

  func body(content: Content) -> some View {
    content
      .onChange(of: formData.sdkEnv) { _, _ in onSave() }
      .onChange(of: formData.apiKey) { _, _ in onSave() }
      .onChange(of: formData.enableLog) { _, _ in onSave() }
      .onChange(of: formData.fontName) { _, _ in onSave() }
      .onChange(of: formData.fontSize) { _, _ in onSave() }
      .onChange(of: formData.separateTextAndButton) { _, _ in onSave() }
  }
}

// MARK: - Items Section Component with Identifiable Items
struct ItemsSectionWithIdentifiers: View {
  @Binding var identifiableItems: [IdentifiableItem]
  let onChange: (() -> Void)?  // Callback when items change

  var body: some View {
    VStack(spacing: 8) {
      // Display existing items with stable UUID identifiers
      ForEach(identifiableItems) { identifiableItem in
        if let index = identifiableItems.firstIndex(where: { $0.id == identifiableItem.id }) {
          ItemRow(
            item: Binding(
              get: { identifiableItems[index].item },
              set: { identifiableItems[index].item = $0 }
            ),
            itemIndex: index,
            onDelete: {
              identifiableItems.removeAll(where: { $0.id == identifiableItem.id })
              onChange?()
            },
            onChange: onChange
          )
        }
      }

      // Add Item Button
      Button(action: {
        identifiableItems.append(
          IdentifiableItem(
            item: Item(
              name: "",
              quantity: 0,
              unitPrice: CurrencyValue(currency: "USD", value: 0),
              sku: ""
            )
          )
        )
        onChange?()
      }) {
        HStack {
          Image(systemName: "plus.circle.fill")
          Text("Add Item")
        }
        .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .padding(.vertical, 8)
    }
  }
}

// MARK: - Items Section Component (Legacy - not used)
struct ItemsSection: View {
  @Binding var items: [Item]
  let onChange: (() -> Void)?

  var body: some View {
    VStack(spacing: 8) {
      // Display existing items
      ForEach(items.indices, id: \.self) { index in
        if index < items.count {
          ItemRow(
            item: $items[index],
            itemIndex: index,
            onDelete: {
              if index < items.count {
                items.remove(at: index)
              }
              onChange?()
            },
            onChange: onChange
          )
        }
      }

      // Add Item Button
      Button(action: {
        items.append(
          Item(
            name: "",
            quantity: 0,
            unitPrice: CurrencyValue(currency: "USD", value: 0),
            sku: ""
          )
        )
        onChange?()
      }) {
        HStack {
          Image(systemName: "plus.circle.fill")
          Text("Add Item")
        }
        .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .padding(.vertical, 8)
    }
  }
}

// MARK: - Item Row Component
struct ItemRow: View {
  @Binding var item: Item
  let itemIndex: Int
  let onDelete: () -> Void
  let onChange: (() -> Void)?  // Callback when item changes
  @State private var isExpanded: Bool = false
  @State private var refreshID = UUID()  // Force view refresh

  var body: some View {
    DisclosureGroup(
      isExpanded: $isExpanded,
      content: {
        VStack(spacing: 12) {
          // 1. Name
          TextField("Name", text: Binding(
            get: { item.name ?? "" },
            set: {
              item.name = $0.isEmpty ? nil : $0
              refreshID = UUID()  // Trigger label refresh
              onChange?()
            }
          ))
          .textFieldStyle(RoundedBorderTextFieldStyle())

          // 2. SKU
          TextField("SKU", text: Binding(
            get: { item.sku ?? "" },
            set: {
              item.sku = $0.isEmpty ? nil : $0
              onChange?()
            }
          ))
          .textFieldStyle(RoundedBorderTextFieldStyle())
          
          // 3. Category
          TextField("Category", text: Binding(
            get: { item.category ?? "" },
            set: {
              item.category = $0.isEmpty ? nil : $0
              onChange?()
            }
          ))
          .textFieldStyle(RoundedBorderTextFieldStyle())

          // 4. Quantity
          TextField("Quantity", text: Binding(
            get: {
              if let qty = item.quantity {
                return String(qty)
              }
              return ""
            },
            set: { newValue in
              item.quantity = Int(newValue)
              onChange?()
            }
          ))
          .keyboardType(.numberPad)
          .textFieldStyle(RoundedBorderTextFieldStyle())

          // 5. Unit Price
          TextField("Unit Price", text: Binding(
            get: {
              if let value = item.unitPrice?.value {
                return String(value)
              }
              return ""
            },
            set: { newValue in
              // Only allow valid integer input
              let filtered = newValue.filter { $0.isNumber }
              if let int64Value = Int64(filtered), !filtered.isEmpty {
                item.unitPrice = CurrencyValue(currency: "USD", value: int64Value)
              } else if filtered.isEmpty {
                item.unitPrice = nil
              }
              refreshID = UUID()  // Trigger label refresh
              onChange?()
            }
          ))
          .keyboardType(.numberPad)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          
          // 6. Unit Tax
          TextField("Unit Tax", text: Binding(
            get: {
              if let value = item.unitTax?.value {
                return String(value)
              }
              return ""
            },
            set: { newValue in
              // Only allow valid integer input
              let filtered = newValue.filter { $0.isNumber }
              if let int64Value = Int64(filtered), !filtered.isEmpty {
                item.unitTax = CurrencyValue(currency: "USD", value: int64Value)
              } else if filtered.isEmpty {
                item.unitTax = nil
              }
              onChange?()
            }
          ))
          .keyboardType(.numberPad)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          
          // 7. Shipping Cost
          TextField("Shipping Cost", text: Binding(
            get: {
              if let value = item.shippingCost?.value {
                return String(value)
              }
              return ""
            },
            set: { newValue in
              // Only allow valid integer input
              let filtered = newValue.filter { $0.isNumber }
              if let int64Value = Int64(filtered), !filtered.isEmpty {
                item.shippingCost = CurrencyValue(currency: "USD", value: int64Value)
              } else if filtered.isEmpty {
                item.shippingCost = nil
              }
              onChange?()
            }
          ))
          .keyboardType(.numberPad)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          
          Picker("Fulfillment Type", selection: $item.fulfillmentType) {
            ForEach([ItemFulfillmentType.pickup, .delivery, .unknown], id: \.self) { option in
              Text(option.rawValue.capitalized).tag(option as ItemFulfillmentType?)
            }
          }
          .pickerStyle(MenuPickerStyle())
          .onChange(of: item.fulfillmentType) { _, _ in
            onChange?()
          }

          Button(role: .destructive, action: onDelete) {
            HStack {
              Image(systemName: "trash")
              Text("Remove Item")
            }
            .frame(maxWidth: .infinity)
          }
          .buttonStyle(.bordered)
        }
        .padding(.vertical, 8)
      },
      label: {
        HStack {
          Text(item.name?.isEmpty == false ? item.name! : "Item \(itemIndex + 1)")
            .font(.headline)
          Spacer()
          if let price = item.unitPrice?.value {
            Text(String(format: "$%.2f", Double(price) / 100.0))
              .foregroundColor(.secondary)
          }
        }
        .id(refreshID)  // Force refresh when refreshID changes
      }
    )
  }
}
