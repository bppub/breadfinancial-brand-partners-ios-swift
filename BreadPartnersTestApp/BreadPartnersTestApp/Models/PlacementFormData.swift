import BreadPartners
import SwiftUI

// MARK: - Form Data Model

struct PlacementFormData: Equatable {
    // Constants for dropdowns
    static let paymentModes = ["FULL", "SPLIT"]
    static let hostEnvs = [
        "QA", "STAGE", "QA_AZ", "PROD", "STAGE_AZ", "PROD_AZ",
    ]
    static let sdkEnvs = BreadPartnersEnvironment.allCases
    static let locationTypes = BreadPartnersLocationType.allCases
    static let financialType = BreadPartnersFinancingType.allCases
    static let fmcApiEnvs = ["DEV", "UAT", "PROD"]
    static let adserverApiEnvs = ["LOCAL", "DEV", "QA", "STAGE", "PROD"]

    var placementId = ""
    var totalPrice = ""
    var location = BreadPartnersLocationType.checkout
    var financial = BreadPartnersFinancingType.card
    var noAction = false
    var loyaltyId = ""
    var campaignID = ""
    var storeNumber = ""
    var overrideKey = ""
    var departmentId = ""
    var prequalCreditLimit = ""
    var prequalificationId = ""
    var financingBuyerId = ""
    var inSessionToken = ""
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
    var accountId = ""
    var applicationId = ""
    var invoiceNumber = ""
    var paymentMode = "FULL"
    var providerConfig = ""
    var skipVerification = false
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
    var env = BreadPartnersEnvironment.stage
    var uqpParams = "embedded=true&clientKey=\(TestAppConstants.brandID)"
    var fontName = "Gentium Plus"
    var fontSize = 16.0
    var primaryColor = Color.black
    var secondaryColor = Color.blue
    var separateTextAndButton = false
    var stylePopup = false
    var popupStyleThemes: PopupStyleThemes = popupStyleThemeConst[0]
    var subTotal: String = ""
    var totalTax: String = ""
    var totalDiscount: String = ""
    var totalShipping: String = ""
    var items: [Item] = []
    
    // Order-level fields
    var discountCode = ""
    var bnplEligible = false

    // Order-level fulfillment fields
    var fulfillmentType: OrderFulfillmentType? = .unknown
    var pickupGivenName = ""
    var pickupFamilyName = ""
    var pickupAdditionalName = ""
    var pickupPhone = ""
    var pickupEmail = ""
    var pickupAddress1 = ""
    var pickupAddress2 = ""
    var pickupLocality = ""
    var pickupRegion = ""
    var pickupPostalCode = ""
    var pickupCountry = ""
    
    // Buyer Information fields
    var buyerGivenName = ""
    var buyerFamilyName = ""
    var buyerAdditionalName = ""
    var buyerBirthDate = ""
    var buyerEmail = ""
    var buyerPhone = ""
    var buyerAlternativePhone = ""
    // Billing Address
    var billingAddress1 = ""
    var billingAddress2 = ""
    var billingLocality = ""
    var billingRegion = ""
    var billingPostalCode = ""
    var billingCountry = ""
    // Shipping Address
    var shippingAddress1 = ""
    var shippingAddress2 = ""
    var shippingLocality = ""
    var shippingRegion = ""
    var shippingPostalCode = ""
    var shippingCountry = ""

    // Custom Equatable implementation
    static func == (lhs: PlacementFormData, rhs: PlacementFormData) -> Bool {
        return lhs.placementId == rhs.placementId &&
            lhs.totalPrice == rhs.totalPrice &&
            lhs.location == rhs.location &&
            lhs.financial == rhs.financial &&
            lhs.noAction == rhs.noAction &&
            lhs.loyaltyId == rhs.loyaltyId &&
            lhs.campaignID == rhs.campaignID &&
            lhs.storeNumber == rhs.storeNumber &&
            lhs.overrideKey == rhs.overrideKey &&
            lhs.departmentId == rhs.departmentId &&
            lhs.prequalCreditLimit == rhs.prequalCreditLimit &&
            lhs.prequalificationId == rhs.prequalificationId &&
            lhs.financingBuyerId == rhs.financingBuyerId &&
            lhs.inSessionToken == rhs.inSessionToken &&
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
            lhs.accountId == rhs.accountId &&
            lhs.applicationId == rhs.applicationId &&
            lhs.invoiceNumber == rhs.invoiceNumber &&
            lhs.paymentMode == rhs.paymentMode &&
            lhs.providerConfig == rhs.providerConfig &&
            lhs.skipVerification == rhs.skipVerification &&
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
            lhs.separateTextAndButton == rhs.separateTextAndButton &&
            lhs.stylePopup == rhs.stylePopup &&
            lhs.popupStyleThemes == rhs.popupStyleThemes &&
            lhs.subTotal == rhs.subTotal &&
            lhs.totalTax == rhs.totalTax &&
            lhs.totalDiscount == rhs.totalDiscount &&
            lhs.totalShipping == rhs.totalShipping &&
            lhs.discountCode == rhs.discountCode &&
            lhs.bnplEligible == rhs.bnplEligible &&
            lhs.fulfillmentType == rhs.fulfillmentType &&
            lhs.pickupGivenName == rhs.pickupGivenName &&
            lhs.pickupFamilyName == rhs.pickupFamilyName &&
            lhs.pickupAdditionalName == rhs.pickupAdditionalName &&
            lhs.pickupPhone == rhs.pickupPhone &&
            lhs.pickupEmail == rhs.pickupEmail &&
            lhs.pickupAddress1 == rhs.pickupAddress1 &&
            lhs.pickupAddress2 == rhs.pickupAddress2 &&
            lhs.pickupLocality == rhs.pickupLocality &&
            lhs.pickupRegion == rhs.pickupRegion &&
            lhs.pickupPostalCode == rhs.pickupPostalCode &&
            lhs.pickupCountry == rhs.pickupCountry &&
            lhs.buyerGivenName == rhs.buyerGivenName &&
            lhs.buyerFamilyName == rhs.buyerFamilyName &&
            lhs.buyerAdditionalName == rhs.buyerAdditionalName &&
            lhs.buyerBirthDate == rhs.buyerBirthDate &&
            lhs.buyerEmail == rhs.buyerEmail &&
            lhs.buyerPhone == rhs.buyerPhone &&
            lhs.buyerAlternativePhone == rhs.buyerAlternativePhone &&
            lhs.billingAddress1 == rhs.billingAddress1 &&
            lhs.billingAddress2 == rhs.billingAddress2 &&
            lhs.billingLocality == rhs.billingLocality &&
            lhs.billingRegion == rhs.billingRegion &&
            lhs.billingPostalCode == rhs.billingPostalCode &&
            lhs.billingCountry == rhs.billingCountry &&
            lhs.shippingAddress1 == rhs.shippingAddress1 &&
            lhs.shippingAddress2 == rhs.shippingAddress2 &&
            lhs.shippingLocality == rhs.shippingLocality &&
            lhs.shippingRegion == rhs.shippingRegion &&
            lhs.shippingPostalCode == rhs.shippingPostalCode &&
            lhs.shippingCountry == rhs.shippingCountry
        // Note: Color comparison and items array comparison omitted for simplicity
        // Color doesn't conform to Equatable, so we skip primaryColor and secondaryColor
        // Items comparison would require Item to conform to Equatable
    }
}

struct PopupStyleThemes: Equatable {
    let name: String
    let primaryColor: UIColor
    let lightColor: UIColor
    let darkColor: UIColor
    let boxColor: UIColor
    let backgroundColor: UIColor
    let smallTextSize: CGFloat
    let mediumTextSize: CGFloat
    let largeTextSize: CGFloat
    let xlargeTextSize: CGFloat
    let cornerRadius: CGFloat
    let headingThreeBold: Bool
    let buttonBackgroundColor: UIColor?

    init(
        name: String,
        primaryColor: UIColor = .black,
        lightColor: UIColor = UIColor(hex: "#767676"),
        darkColor: UIColor = .black,
        boxColor: UIColor = UIColor(hex: "#ececec"),
        backgroundColor: UIColor = .white,
        smallTextSize: CGFloat = 10.0,
        mediumTextSize: CGFloat = 14.0,
        largeTextSize: CGFloat = 14.0,
        xlargeTextSize: CGFloat = 16.0,
        cornerRadius: CGFloat = 8.0,
        headingThreeBold: Bool = true,
        buttonBackgroundColor: UIColor? = nil
    ) {
        self.name = name
        self.primaryColor = primaryColor
        self.lightColor = lightColor
        self.darkColor = darkColor
        self.boxColor = boxColor
        self.backgroundColor = backgroundColor
        self.smallTextSize = smallTextSize
        self.mediumTextSize = mediumTextSize
        self.largeTextSize = largeTextSize
        self.xlargeTextSize = xlargeTextSize
        self.cornerRadius = cornerRadius
        self.headingThreeBold = headingThreeBold
        self.buttonBackgroundColor = buttonBackgroundColor
    }

    static func == (lhs: PopupStyleThemes, rhs: PopupStyleThemes) -> Bool {
        return lhs.name == rhs.name &&
            lhs.primaryColor == rhs.primaryColor &&
            lhs.lightColor == rhs.lightColor &&
            lhs.darkColor == rhs.darkColor &&
            lhs.boxColor == rhs.boxColor &&
            lhs.smallTextSize == rhs.smallTextSize &&
            lhs.mediumTextSize == rhs.mediumTextSize &&
            lhs.largeTextSize == rhs.largeTextSize &&
            lhs.xlargeTextSize == rhs.xlargeTextSize &&
            lhs.cornerRadius == rhs.cornerRadius &&
            lhs.headingThreeBold == rhs.headingThreeBold
    }
}

let popupStyleThemeConst: [PopupStyleThemes] = [
    PopupStyleThemes(
        name: "Green - Not Bold",
        primaryColor: UIColor(hex: "#28A745"),
        lightColor: UIColor(hex: "#68ba7b"),
        darkColor: UIColor(hex: "#19692C"),
        boxColor: UIColor(hex: "#E6F9EF"),
        smallTextSize: 13,
        mediumTextSize: 16,
        largeTextSize: 19,
        xlargeTextSize: 22,
        cornerRadius: 0,
        headingThreeBold: false
    ),
    PopupStyleThemes(
        name: "Blue - Bold",
        primaryColor: UIColor(hex: "#007BFF"),
        lightColor: UIColor(hex: "#6da3de"),
        darkColor: UIColor(hex: "#003F7F"),
        boxColor: UIColor(hex: "#EAF4FF"),
        smallTextSize: 14,
        mediumTextSize: 17,
        largeTextSize: 20,
        xlargeTextSize: 24,
        cornerRadius: 10,
        headingThreeBold: true
    ),
    PopupStyleThemes(
        name: "Orange - Not Bold",
        primaryColor: UIColor(hex: "#FF8C00"),
        lightColor: UIColor(hex: "#FFDAB9"),
        darkColor: UIColor(hex: "#8B4500"),
        boxColor: UIColor(hex: "#FFF4E5"),
        smallTextSize: 12,
        mediumTextSize: 14,
        largeTextSize: 18,
        xlargeTextSize: 21,
        cornerRadius: 25,
        headingThreeBold: false
    ),
    PopupStyleThemes(
        name: "Purple - Bold",
        primaryColor: UIColor(hex: "#800080"),
        lightColor: UIColor(hex: "#D8BFD8"),
        darkColor: UIColor(hex: "#4B0082"),
        boxColor: UIColor(hex: "#F5F0FF"),
        smallTextSize: 13,
        mediumTextSize: 16,
        largeTextSize: 19,
        xlargeTextSize: 23,
        cornerRadius: 50,
        headingThreeBold: true
    ),
    PopupStyleThemes(
        name: "Background Color",
        backgroundColor: UIColor(red: 25/255, green: 70/255, blue: 200/255, alpha: 15/255),
        headingThreeBold: false,
        buttonBackgroundColor: UIColor(hex: "#1946c8")
    ),
]
