//
//  PreferencesManager.swift
//  BreadPartnersTestAppSwift
//
//  Created by Joncarlos Tavarez on 3/6/26.
//

import Foundation
import SwiftUI
import BreadPartners

/// PreferencesManager handles caching and persistence of PlacementFormData using UserDefaults
class PreferencesManager {
    // MARK: - Singleton

    static let shared = PreferencesManager()
    
    // MARK: - Keys

    private enum Keys {
        static let placementFormData = "placementFormData"
        static let rtpsFormData = "rtpsFormData"
    }
    
    private let userDefaults: UserDefaults
    
    // MARK: - Initialization

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - PlacementFormData Caching
    
    /// Save PlacementFormData to cache
    func savePlacementFormData(_ formData: PlacementFormData) {
        let codableData = CodablePlacementFormData(from: formData)
        if let encoded = try? JSONEncoder().encode(codableData) {
            self.userDefaults.set(encoded, forKey: Keys.placementFormData)
        }
    }
    
    /// Load PlacementFormData from cache
    func loadPlacementFormData() -> PlacementFormData? {
        guard let data = userDefaults.data(forKey: Keys.placementFormData),
              let codableData = try? JSONDecoder().decode(CodablePlacementFormData.self, from: data)
        else {
            return nil
        }
        return codableData.toPlacementFormData()
    }
    
    /// Clear cached PlacementFormData
    func clearPlacementFormData() {
        self.userDefaults.removeObject(forKey: Keys.placementFormData)
    }
    
    // MARK: - RTPSFormData Caching
    
    /// Save RTPSFormData to cache
    func saveRTPSFormData(_ formData: RTPSFormData) {
        let codableData = CodableRTPSFormData(from: formData)
        if let encoded = try? JSONEncoder().encode(codableData) {
            self.userDefaults.set(encoded, forKey: Keys.rtpsFormData)
        }
    }
    
    /// Load RTPSFormData from cache
    func loadRTPSFormData() -> RTPSFormData? {
        guard let data = userDefaults.data(forKey: Keys.rtpsFormData),
              let codableData = try? JSONDecoder().decode(CodableRTPSFormData.self, from: data)
        else {
            return nil
        }
        return codableData.toRTPSFormData()
    }
    
    /// Clear cached RTPSFormData
    func clearRTPSFormData() {
        self.userDefaults.removeObject(forKey: Keys.rtpsFormData)
    }
    
    // MARK: - Generic Caching Methods
    
    /// Save any Codable value
    func save<T: Encodable>(_ value: T, forKey key: String) {
        if let encoded = try? JSONEncoder().encode(value) {
            self.userDefaults.set(encoded, forKey: key)
        }
    }
    
    /// Load any Codable value
    func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    /// Save string value
    func saveString(_ value: String, forKey key: String) {
        self.userDefaults.set(value, forKey: key)
    }
    
    /// Load string value
    func loadString(forKey key: String) -> String? {
        return self.userDefaults.string(forKey: key)
    }
    
    /// Save bool value
    func saveBool(_ value: Bool, forKey key: String) {
        self.userDefaults.set(value, forKey: key)
    }
    
    /// Load bool value
    func loadBool(forKey key: String) -> Bool {
        return self.userDefaults.bool(forKey: key)
    }
    
    /// Save double value
    func saveDouble(_ value: Double, forKey key: String) {
        self.userDefaults.set(value, forKey: key)
    }
    
    /// Load double value
    func loadDouble(forKey key: String) -> Double {
        return self.userDefaults.double(forKey: key)
    }
    
    /// Clear value for specific key
    func clearValue(forKey key: String) {
        self.userDefaults.removeObject(forKey: key)
    }
    
    /// Clear all cached data
    func clearAll() {
        if let bundleID = Bundle.main.bundleIdentifier {
            self.userDefaults.removePersistentDomain(forName: bundleID)
        }
    }
}

// MARK: - Codable Wrapper for PlacementFormData

/// Codable wrapper to enable encoding/decoding of PlacementFormData
struct CodablePlacementFormData: Codable {
    var placementId: String
    var totalPrice: String
    var locationRawValue: String
    var financialRawValue: String
    var noAction: Bool
    var loyaltyId: String
    var campaignID: String
    var storeNumber: String
    var overrideKey: String
    var departmentId: String
    var prequalCreditLimit: String
    var prequalificationId: String
    var financingBuyerId: String
    var inSessionToken: String
    var cardholderTier: String
    var channel: String
    var subchannel: String
    var clientVar1: String
    var clientVar2: String
    var clientVar3: String
    var clientVar4: String
    var allowCheckout: Bool
    var selectedCardKey: String
    var defaultSelectedCardKey: String
    var accountId: String
    var applicationId: String
    var invoiceNumber: String
    var paymentMode: String
    var providerConfig: String
    var skipVerification: Bool
    var sdkHostEnv: String
    var sdkEnvRawValue: String
    var fmcApiEnv: String
    var adserverApiEnv: String
    var apiKey: String
    var clientName: String
    var enableLog: Bool
    var enableAnalytics: Bool
    var enableSessionData: Bool
    var sdkTid: String
    var envRawValue: String
    var uqpParams: String
    var fontName: String
    var fontSize: Double
    var primaryColorHex: String
    var secondaryColorHex: String
    var separateTextAndButton: Bool
    var stylePopup: Bool
    var popupStyleThemeName: String?
    var subTotal: String
    var totalTax: String
    var totalDiscount: String
    var totalShipping: String
    var items: [CodableItem]
    var discountCode: String
    var bnplEligible: Bool
    var fulfillmentTypeRawValue: String?
    var pickupGivenName: String
    var pickupFamilyName: String
    var pickupAdditionalName: String
    var pickupPhone: String
    var pickupEmail: String
    var pickupAddress1: String
    var pickupAddress2: String
    var pickupLocality: String
    var pickupRegion: String
    var pickupPostalCode: String
    var pickupCountry: String
    var buyerGivenName: String
    var buyerFamilyName: String
    var buyerAdditionalName: String
    var buyerBirthDate: String
    var buyerEmail: String
    var buyerPhone: String
    var buyerAlternativePhone: String
    var billingAddress1: String
    var billingAddress2: String
    var billingLocality: String
    var billingRegion: String
    var billingPostalCode: String
    var billingCountry: String
    var shippingAddress1: String
    var shippingAddress2: String
    var shippingLocality: String
    var shippingRegion: String
    var shippingPostalCode: String
    var shippingCountry: String
    
    /// Initialize from PlacementFormData
    init(from formData: PlacementFormData) {
        self.placementId = formData.placementId
        self.totalPrice = formData.totalPrice
        self.locationRawValue = formData.location.rawValue
        self.financialRawValue = formData.financial.rawValue
        self.noAction = formData.noAction
        self.loyaltyId = formData.loyaltyId
        self.campaignID = formData.campaignID
        self.storeNumber = formData.storeNumber
        self.overrideKey = formData.overrideKey
        self.departmentId = formData.departmentId
        self.prequalCreditLimit = formData.prequalCreditLimit
        self.prequalificationId = formData.prequalificationId
        self.financingBuyerId = formData.financingBuyerId
        self.inSessionToken = formData.inSessionToken
        self.cardholderTier = formData.cardholderTier
        self.channel = formData.channel
        self.subchannel = formData.subchannel
        self.clientVar1 = formData.clientVar1
        self.clientVar2 = formData.clientVar2
        self.clientVar3 = formData.clientVar3
        self.clientVar4 = formData.clientVar4
        self.allowCheckout = formData.allowCheckout
        self.selectedCardKey = formData.selectedCardKey
        self.defaultSelectedCardKey = formData.defaultSelectedCardKey
        self.accountId = formData.accountId
        self.applicationId = formData.applicationId
        self.invoiceNumber = formData.invoiceNumber
        self.paymentMode = formData.paymentMode
        self.providerConfig = formData.providerConfig
        self.skipVerification = formData.skipVerification
        self.sdkHostEnv = formData.sdkHostEnv
        self.sdkEnvRawValue = formData.sdkEnv.rawValue
        self.fmcApiEnv = formData.fmcApiEnv
        self.adserverApiEnv = formData.adserverApiEnv
        self.apiKey = formData.apiKey
        self.clientName = formData.clientName
        self.enableLog = formData.enableLog
        self.enableAnalytics = formData.enableAnalytics
        self.enableSessionData = formData.enableSessionData
        self.sdkTid = formData.sdkTid
        self.envRawValue = formData.env.rawValue
        self.uqpParams = formData.uqpParams
        self.fontName = formData.fontName
        self.fontSize = formData.fontSize
        self.primaryColorHex = formData.primaryColor.toHex()
        self.secondaryColorHex = formData.secondaryColor.toHex()
        self.separateTextAndButton = formData.separateTextAndButton
        self.stylePopup = formData.stylePopup
        self.popupStyleThemeName = formData.popupStyleThemes.name
        self.subTotal = formData.subTotal
        self.totalTax = formData.totalTax
        self.totalDiscount = formData.totalDiscount
        self.totalShipping = formData.totalShipping
        self.items = formData.items.map { CodableItem(from: $0) }
        self.discountCode = formData.discountCode
        self.bnplEligible = formData.bnplEligible
        self.fulfillmentTypeRawValue = formData.fulfillmentType?.rawValue
        self.pickupGivenName = formData.pickupGivenName
        self.pickupFamilyName = formData.pickupFamilyName
        self.pickupAdditionalName = formData.pickupAdditionalName
        self.pickupPhone = formData.pickupPhone
        self.pickupEmail = formData.pickupEmail
        self.pickupAddress1 = formData.pickupAddress1
        self.pickupAddress2 = formData.pickupAddress2
        self.pickupLocality = formData.pickupLocality
        self.pickupRegion = formData.pickupRegion
        self.pickupPostalCode = formData.pickupPostalCode
        self.pickupCountry = formData.pickupCountry
        self.buyerGivenName = formData.buyerGivenName
        self.buyerFamilyName = formData.buyerFamilyName
        self.buyerAdditionalName = formData.buyerAdditionalName
        self.buyerBirthDate = formData.buyerBirthDate
        self.buyerEmail = formData.buyerEmail
        self.buyerPhone = formData.buyerPhone
        self.buyerAlternativePhone = formData.buyerAlternativePhone
        self.billingAddress1 = formData.billingAddress1
        self.billingAddress2 = formData.billingAddress2
        self.billingLocality = formData.billingLocality
        self.billingRegion = formData.billingRegion
        self.billingPostalCode = formData.billingPostalCode
        self.billingCountry = formData.billingCountry
        self.shippingAddress1 = formData.shippingAddress1
        self.shippingAddress2 = formData.shippingAddress2
        self.shippingLocality = formData.shippingLocality
        self.shippingRegion = formData.shippingRegion
        self.shippingPostalCode = formData.shippingPostalCode
        self.shippingCountry = formData.shippingCountry
    }
    
    /// Convert to PlacementFormData
    func toPlacementFormData() -> PlacementFormData {
        var formData = PlacementFormData()
        formData.placementId = self.placementId
        formData.totalPrice = self.totalPrice
        formData.location = BreadPartnersLocationType(rawValue: self.locationRawValue) ?? .checkout
        formData.financial = BreadPartnersFinancingType(rawValue: self.financialRawValue) ?? .card
        formData.noAction = self.noAction
        formData.loyaltyId = self.loyaltyId
        formData.campaignID = self.campaignID
        formData.storeNumber = self.storeNumber
        formData.overrideKey = self.overrideKey
        formData.departmentId = self.departmentId
        formData.prequalCreditLimit = self.prequalCreditLimit
        formData.prequalificationId = self.prequalificationId
        formData.financingBuyerId = self.financingBuyerId
        formData.inSessionToken = self.inSessionToken
        formData.cardholderTier = self.cardholderTier
        formData.channel = self.channel
        formData.subchannel = self.subchannel
        formData.clientVar1 = self.clientVar1
        formData.clientVar2 = self.clientVar2
        formData.clientVar3 = self.clientVar3
        formData.clientVar4 = self.clientVar4
        formData.allowCheckout = self.allowCheckout
        formData.selectedCardKey = self.selectedCardKey
        formData.defaultSelectedCardKey = self.defaultSelectedCardKey
        formData.accountId = self.accountId
        formData.applicationId = self.applicationId
        formData.invoiceNumber = self.invoiceNumber
        formData.paymentMode = self.paymentMode
        formData.providerConfig = self.providerConfig
        formData.skipVerification = self.skipVerification
        formData.sdkHostEnv = self.sdkHostEnv
        formData.sdkEnv = BreadPartnersEnvironment(rawValue: self.sdkEnvRawValue) ?? .stage
        formData.fmcApiEnv = self.fmcApiEnv
        formData.adserverApiEnv = self.adserverApiEnv
        formData.apiKey = self.apiKey
        formData.clientName = self.clientName
        formData.enableLog = self.enableLog
        formData.enableAnalytics = self.enableAnalytics
        formData.enableSessionData = self.enableSessionData
        formData.sdkTid = self.sdkTid
        formData.env = BreadPartnersEnvironment(rawValue: self.envRawValue) ?? .stage
        formData.uqpParams = self.uqpParams
        formData.fontName = self.fontName
        formData.fontSize = self.fontSize
        formData.primaryColor = Color(hex: self.primaryColorHex)
        formData.secondaryColor = Color(hex: self.secondaryColorHex)
        formData.separateTextAndButton = self.separateTextAndButton
        formData.stylePopup = self.stylePopup
        formData.popupStyleThemes = popupStyleThemeConst.first { $0.name == self.popupStyleThemeName } ?? popupStyleThemeConst[0]
        formData.subTotal = self.subTotal
        formData.totalTax = self.totalTax
        formData.totalDiscount = self.totalDiscount
        formData.totalShipping = self.totalShipping
        formData.items = self.items.map { $0.toItem() }
        formData.discountCode = self.discountCode
        formData.bnplEligible = self.bnplEligible
        formData.fulfillmentType = self.fulfillmentTypeRawValue.flatMap { OrderFulfillmentType(rawValue: $0) }
        formData.pickupGivenName = self.pickupGivenName
        formData.pickupFamilyName = self.pickupFamilyName
        formData.pickupAdditionalName = self.pickupAdditionalName
        formData.pickupPhone = self.pickupPhone
        formData.pickupEmail = self.pickupEmail
        formData.pickupAddress1 = self.pickupAddress1
        formData.pickupAddress2 = self.pickupAddress2
        formData.pickupLocality = self.pickupLocality
        formData.pickupRegion = self.pickupRegion
        formData.pickupPostalCode = self.pickupPostalCode
        formData.pickupCountry = self.pickupCountry
        formData.buyerGivenName = self.buyerGivenName
        formData.buyerFamilyName = self.buyerFamilyName
        formData.buyerAdditionalName = self.buyerAdditionalName
        formData.buyerBirthDate = self.buyerBirthDate
        formData.buyerEmail = self.buyerEmail
        formData.buyerPhone = self.buyerPhone
        formData.buyerAlternativePhone = self.buyerAlternativePhone
        formData.billingAddress1 = self.billingAddress1
        formData.billingAddress2 = self.billingAddress2
        formData.billingLocality = self.billingLocality
        formData.billingRegion = self.billingRegion
        formData.billingPostalCode = self.billingPostalCode
        formData.billingCountry = self.billingCountry
        formData.shippingAddress1 = self.shippingAddress1
        formData.shippingAddress2 = self.shippingAddress2
        formData.shippingLocality = self.shippingLocality
        formData.shippingRegion = self.shippingRegion
        formData.shippingPostalCode = self.shippingPostalCode
        formData.shippingCountry = self.shippingCountry
        return formData
    }
}

// MARK: - Codable Item Wrapper

struct CodableItem: Codable {
    var name: String?
    var category: String?
    var quantity: Int64?
    var sku: String?
    var unitPrice: Int64?
    var unitTax: Int64?
    var shippingCost: Int64?
    var fulfillmentTypeRawValue: String?
    
    init(from item: Item) {
        self.name = item.name
        self.category = item.category
        self.quantity = item.quantity.map { Int64($0) }
        self.sku = item.sku
        self.unitPrice = item.unitPrice?.value
        self.unitTax = item.unitTax?.value
        self.shippingCost = item.shippingCost?.value
        self.fulfillmentTypeRawValue = item.fulfillmentType?.rawValue
    }
    
    func toItem() -> Item {
        return Item(
            name: self.name,
            category: self.category,
            quantity: self.quantity.map { Int($0) },
            unitPrice: self.unitPrice != nil ? CurrencyValue(currency: "USD", value: self.unitPrice!) : nil,
            unitTax: self.unitTax != nil ? CurrencyValue(currency: "USD", value: self.unitTax!) : nil,
            sku: self.sku,
            shippingCost: self.shippingCost != nil ? CurrencyValue(currency: "USD", value: self.shippingCost!) : nil,
            fulfillmentType: self.fulfillmentTypeRawValue.flatMap { ItemFulfillmentType(rawValue: $0) }
        )
    }
}

// MARK: - Codable Wrapper for RTPSFormData

/// Codable wrapper to enable encoding/decoding of RTPSFormData
struct CodableRTPSFormData: Codable {
    var firstName: String
    var middleName: String
    var lastName: String
    var addressOne: String
    var addressTwo: String
    var city: String
    var state: String
    var country: String
    var zip: String
    var preScreenID: String
    var email: String
    var mobile: String
    var alternateMobile: String
    var cardAmount: String
    var cardType: String
    var storeNumber: String
    var loyaltyNumber: String
    var customerNumber: String
    var productAmount: String
    var checkoutAmount: String
    var category: String
    var sku: String
    var correlationData: String
    var overrideKey: String
    var cardChoiceCode: String
    var departmentId: String
    var existing: Bool
    var cardholderTier: String
    var channel: String
    var subchannel: String
    var clientVar1: String
    var clientVar2: String
    var clientVar3: String
    var clientVar4: String
    var allowCheckout: Bool
    var selectedCardKey: String
    var defaultSelectedCardKey: String
    var customerAcceptedOffer: Bool?
    var mockTestRawValue: String
    var locationRawValue: String
    var financialRawValue: String
    var sdkHostEnv: String
    var sdkEnvRawValue: String
    var fmcApiEnv: String
    var adserverApiEnv: String
    var apiKey: String
    var clientName: String
    var enableLog: Bool
    var enableAnalytics: Bool
    var enableSessionData: Bool
    var sdkTid: String
    var env: String
    var uqpParams: String
    var fontName: String
    var fontSize: Double
    var primaryColorHex: String
    var secondaryColorHex: String
    var separateTextAndButton: Bool
    
    /// Initialize from RTPSFormData
    init(from formData: RTPSFormData) {
        self.firstName = formData.firstName
        self.middleName = formData.middleName
        self.lastName = formData.lastName
        self.addressOne = formData.addressOne
        self.addressTwo = formData.addressTwo
        self.city = formData.city
        self.state = formData.state
        self.country = formData.country
        self.zip = formData.zip
        self.preScreenID = formData.preScreenID
        self.email = formData.email
        self.mobile = formData.mobile
        self.alternateMobile = formData.alternateMobile
        self.cardAmount = formData.cardAmount
        self.cardType = formData.cardType
        self.storeNumber = formData.storeNumber
        self.loyaltyNumber = formData.loyaltyNumber
        self.customerNumber = formData.customerNumber
        self.productAmount = formData.productAmount
        self.checkoutAmount = formData.checkoutAmount
        self.category = formData.category
        self.sku = formData.sku
        self.correlationData = formData.correlationData
        self.overrideKey = formData.overrideKey
        self.cardChoiceCode = formData.cardChoiceCode
        self.departmentId = formData.departmentId
        self.existing = formData.existing
        self.cardholderTier = formData.cardholderTier
        self.channel = formData.channel
        self.subchannel = formData.subchannel
        self.clientVar1 = formData.clientVar1
        self.clientVar2 = formData.clientVar2
        self.clientVar3 = formData.clientVar3
        self.clientVar4 = formData.clientVar4
        self.allowCheckout = formData.allowCheckout
        self.selectedCardKey = formData.selectedCardKey
        self.defaultSelectedCardKey = formData.defaultSelectedCardKey
        self.customerAcceptedOffer = formData.customerAcceptedOffer
        self.mockTestRawValue = formData.mockTest.rawValue
        self.locationRawValue = formData.location.rawValue
        self.financialRawValue = formData.financial.rawValue
        self.sdkHostEnv = formData.sdkHostEnv
        self.sdkEnvRawValue = formData.sdkEnv.rawValue
        self.fmcApiEnv = formData.fmcApiEnv
        self.adserverApiEnv = formData.adserverApiEnv
        self.apiKey = formData.apiKey
        self.clientName = formData.clientName
        self.enableLog = formData.enableLog
        self.enableAnalytics = formData.enableAnalytics
        self.enableSessionData = formData.enableSessionData
        self.sdkTid = formData.sdkTid
        self.env = formData.env
        self.uqpParams = formData.uqpParams
        self.fontName = formData.fontName
        self.fontSize = formData.fontSize
        self.primaryColorHex = formData.primaryColor.toHex()
        self.secondaryColorHex = formData.secondaryColor.toHex()
        self.separateTextAndButton = formData.separateTextAndButton
    }
    
    /// Convert to RTPSFormData
    func toRTPSFormData() -> RTPSFormData {
        var formData = RTPSFormData()
        formData.firstName = self.firstName
        formData.middleName = self.middleName
        formData.lastName = self.lastName
        formData.addressOne = self.addressOne
        formData.addressTwo = self.addressTwo
        formData.city = self.city
        formData.state = self.state
        formData.country = self.country
        formData.zip = self.zip
        formData.preScreenID = self.preScreenID
        formData.email = self.email
        formData.mobile = self.mobile
        formData.alternateMobile = self.alternateMobile
        formData.cardAmount = self.cardAmount
        formData.cardType = self.cardType
        formData.storeNumber = self.storeNumber
        formData.loyaltyNumber = self.loyaltyNumber
        formData.customerNumber = self.customerNumber
        formData.productAmount = self.productAmount
        formData.checkoutAmount = self.checkoutAmount
        formData.category = self.category
        formData.sku = self.sku
        formData.correlationData = self.correlationData
        formData.overrideKey = self.overrideKey
        formData.cardChoiceCode = self.cardChoiceCode
        formData.departmentId = self.departmentId
        formData.existing = self.existing
        formData.cardholderTier = self.cardholderTier
        formData.channel = self.channel
        formData.subchannel = self.subchannel
        formData.clientVar1 = self.clientVar1
        formData.clientVar2 = self.clientVar2
        formData.clientVar3 = self.clientVar3
        formData.clientVar4 = self.clientVar4
        formData.allowCheckout = self.allowCheckout
        formData.selectedCardKey = self.selectedCardKey
        formData.defaultSelectedCardKey = self.defaultSelectedCardKey
        formData.customerAcceptedOffer = self.customerAcceptedOffer
        formData.mockTest = BreadPartnersMockOptions(rawValue: self.mockTestRawValue) ?? .success
        formData.location = BreadPartnersLocationType(rawValue: self.locationRawValue) ?? .checkout
        formData.financial = BreadPartnersFinancingType(rawValue: self.financialRawValue) ?? .installments
        formData.sdkHostEnv = self.sdkHostEnv
        formData.sdkEnv = BreadPartnersEnvironment(rawValue: self.sdkEnvRawValue) ?? .stage
        formData.fmcApiEnv = self.fmcApiEnv
        formData.adserverApiEnv = self.adserverApiEnv
        formData.apiKey = self.apiKey
        formData.clientName = self.clientName
        formData.enableLog = self.enableLog
        formData.enableAnalytics = self.enableAnalytics
        formData.enableSessionData = self.enableSessionData
        formData.sdkTid = self.sdkTid
        formData.env = self.env
        formData.uqpParams = self.uqpParams
        formData.fontName = self.fontName
        formData.fontSize = self.fontSize
        formData.primaryColor = Color(hex: self.primaryColorHex)
        formData.secondaryColor = Color(hex: self.secondaryColorHex)
        formData.separateTextAndButton = self.separateTextAndButton
        return formData
    }
}

// MARK: - Color Extensions for Hex Conversion

extension Color {
    /// Convert Color to hex string
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else {
            return "#000000"
        }
        
        let r = components[0]
        let g = components.count > 1 ? components[1] : 0
        let b = components.count > 2 ? components[2] : 0
        
        return String(format: "#%02lX%02lX%02lX",
                      lroundf(Float(r * 255)),
                      lroundf(Float(g * 255)),
                      lroundf(Float(b * 255)))
    }
    
    /// Initialize Color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - PlacementFormData Extension for Convenience

extension PlacementFormData {
    /// Save this form data to cache
    func cache() {
        PreferencesManager.shared.savePlacementFormData(self)
    }
    
    /// Load cached form data
    static func loadCached() -> PlacementFormData? {
        return PreferencesManager.shared.loadPlacementFormData()
    }
    
    /// Clear cached form data
    static func clearCache() {
        PreferencesManager.shared.clearPlacementFormData()
    }
}

// MARK: - RTPSFormData Extension for Convenience

extension RTPSFormData {
    /// Save this form data to cache
    mutating func cache() {
        PreferencesManager.shared.saveRTPSFormData(self)
    }
    
    /// Load cached form data
    static func loadCached() -> RTPSFormData? {
        return PreferencesManager.shared.loadRTPSFormData()
    }
    
    /// Clear cached form data
    static func clearCache() {
        PreferencesManager.shared.clearRTPSFormData()
    }
}
