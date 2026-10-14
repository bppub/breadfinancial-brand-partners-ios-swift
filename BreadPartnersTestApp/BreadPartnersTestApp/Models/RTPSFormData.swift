import SwiftUI
import BreadPartners
import Foundation

// MARK: - Form Data Model
struct RTPSFormData: Equatable {
    // Constants for dropdowns
    static let paymentModes = ["FULL", "SPLIT"]
    static let hostEnvs = ["QA","STAGE", "QA_AZ","PROD","STAGE_AZ", "PROD_AZ"]
    static let sdkEnvs = BreadPartnersEnvironment.allCases
    static let fmcApiEnvs = [ "DEV", "UAT", "PROD"]
    static let adserverApiEnvs = ["LOCAL", "DEV", "QA", "STAGE", "PROD"]
    static let mockTestCase = BreadPartnersMockOptions.allCases
    static let locationTypes = BreadPartnersLocationType.allCases
    static let financialType = BreadPartnersFinancingType.allCases
    

    var firstName = ""
    var middleName = ""
    var lastName = ""
    var addressOne = ""
    var addressTwo = ""
    var city = ""
    var state = ""
    var country = ""
    var zip = ""
    var preScreenID = ""
    var email = ""
    var mobile = ""
    var alternateMobile = ""
    var cardAmount = ""
    var cardType = ""
    var storeNumber = ""
    var loyaltyNumber = ""
    var customerNumber = ""
    var productAmount = ""
    var checkoutAmount = ""
    var category = ""
    var sku = ""
    var correlationData = ""
    var overrideKey = ""
    var cardChoiceCode = ""
    var departmentId = ""
    var existing = false
    var cardholderTier = ""
    var channel = ""
    var subchannel = ""
    var clientVar1 = ""
    var clientVar2 = ""
    var clientVar3 = ""
    var clientVar4 = ""
    var allowCheckout = false
    var selectedCardKey = ""
    var defaultSelectedCardKey = ""
    var customerAcceptedOffer: Bool? = nil
    var mockTest = BreadPartnersMockOptions.noMock
    var location = BreadPartnersLocationType.checkout
    var financial = BreadPartnersFinancingType.installments
    
    var sdkHostEnv = "STAGE"
    var sdkEnv = BreadPartnersEnvironment.stage
    var fmcApiEnv = "UAT"
    var adserverApiEnv = "PROD"
    var apiKey = TestAppConstants.brandID
    var clientName = TestAppConstants.clientName
    var enableLog = true
    var enableAnalytics = false
    var enableSessionData = false
    var sdkTid = ""
    var env = "STAGE"
    var uqpParams = "embedded=true&clientKey=\(TestAppConstants.brandID)"
    var fontName = "Gentium Plus"
    var fontSize = 16.0
    var primaryColor = Color.black
    var secondaryColor = Color.blue
    var separateTextAndButton = false
    
    // Custom Equatable implementation
    static func == (lhs: RTPSFormData, rhs: RTPSFormData) -> Bool {
        return lhs.firstName == rhs.firstName &&
            lhs.middleName == rhs.middleName &&
            lhs.lastName == rhs.lastName &&
            lhs.addressOne == rhs.addressOne &&
            lhs.addressTwo == rhs.addressTwo &&
            lhs.city == rhs.city &&
            lhs.state == rhs.state &&
            lhs.country == rhs.country &&
            lhs.zip == rhs.zip &&
            lhs.preScreenID == rhs.preScreenID &&
            lhs.email == rhs.email &&
            lhs.mobile == rhs.mobile &&
            lhs.alternateMobile == rhs.alternateMobile &&
            lhs.cardAmount == rhs.cardAmount &&
            lhs.cardType == rhs.cardType &&
            lhs.storeNumber == rhs.storeNumber &&
            lhs.loyaltyNumber == rhs.loyaltyNumber &&
            lhs.customerNumber == rhs.customerNumber &&
            lhs.productAmount == rhs.productAmount &&
            lhs.checkoutAmount == rhs.checkoutAmount &&
            lhs.category == rhs.category &&
            lhs.sku == rhs.sku &&
            lhs.correlationData == rhs.correlationData &&
            lhs.overrideKey == rhs.overrideKey &&
            lhs.cardChoiceCode == rhs.cardChoiceCode &&
            lhs.departmentId == rhs.departmentId &&
            lhs.existing == rhs.existing &&
            lhs.cardholderTier == rhs.cardholderTier &&
            lhs.channel == rhs.channel &&
            lhs.subchannel == rhs.subchannel &&
            lhs.clientVar1 == rhs.clientVar1 &&
            lhs.clientVar2 == rhs.clientVar2 &&
            lhs.clientVar3 == rhs.clientVar3 &&
            lhs.clientVar4 == rhs.clientVar4 &&
            lhs.allowCheckout == rhs.allowCheckout &&
            lhs.selectedCardKey == rhs.selectedCardKey &&
            lhs.defaultSelectedCardKey == rhs.defaultSelectedCardKey &&
            lhs.customerAcceptedOffer == rhs.customerAcceptedOffer &&
            lhs.mockTest == rhs.mockTest &&
            lhs.location == rhs.location &&
            lhs.financial == rhs.financial &&
            lhs.sdkHostEnv == rhs.sdkHostEnv &&
            lhs.sdkEnv == rhs.sdkEnv &&
            lhs.fmcApiEnv == rhs.fmcApiEnv &&
            lhs.adserverApiEnv == rhs.adserverApiEnv &&
            lhs.apiKey == rhs.apiKey &&
            lhs.clientName == rhs.clientName &&
            lhs.enableLog == rhs.enableLog &&
            lhs.enableAnalytics == rhs.enableAnalytics &&
            lhs.enableSessionData == rhs.enableSessionData &&
            lhs.sdkTid == rhs.sdkTid &&
            lhs.env == rhs.env &&
            lhs.uqpParams == rhs.uqpParams &&
            lhs.fontName == rhs.fontName &&
            lhs.fontSize == rhs.fontSize &&
            lhs.separateTextAndButton == rhs.separateTextAndButton
        // Note: Color comparison omitted for simplicity
        // Color doesn't conform to Equatable, so we skip primaryColor and secondaryColor
    }
}
