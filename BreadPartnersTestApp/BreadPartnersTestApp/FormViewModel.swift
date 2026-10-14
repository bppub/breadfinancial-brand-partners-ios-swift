import BreadPartners
import Combine
import Foundation
import UIKit

// MARK: - View Models
class FormViewModel: ObservableObject {
    @Published var textWithLinkResponse: BreadPartnerLinkTextSwitUI?
    @Published var textWithButton:
        (BreadPartnerTextView, BreadPartnerButtonView)?

    @Published var overlayResponse: UIViewController?
    @Published var isLoading = false
    @Published var error: Error?

    @Published var logs: String = "No Logs"

    func generatePlacements(formData: PlacementFormData, onUnifiedOffersReceived: ((String, String, String, String) -> Void)? = nil) {
        isLoading = true
        textWithLinkResponse = nil
        textWithButton = nil
        overlayResponse = nil
        error = nil
        logs = "No Logs"

        /// Prepare popup styling configuration object for each style elemnt
        let popUpStyling = PopUpStyling(
            loaderColor: formData.popupStyleThemes.primaryColor,
            crossColor: formData.popupStyleThemes.primaryColor,
            dividerColor: formData.popupStyleThemes.boxColor,
            borderColor: formData.popupStyleThemes.boxColor.cgColor,
            backgroundColor: formData.popupStyleThemes.backgroundColor,
            titlePopupTextStyle: PopupTextStyle(
                font: UIFont(
                    name: formData.fontName, size: Double(formData.popupStyleThemes.xlargeTextSize)
                ),
                textColor: formData.popupStyleThemes.darkColor
            ),
            subTitlePopupTextStyle: PopupTextStyle(
                font: UIFont(
                    name: formData.fontName, size: Double(formData.popupStyleThemes.mediumTextSize)
                ),
                textColor: formData.popupStyleThemes.lightColor
            ),
            headerPopupTextStyle: PopupTextStyle(
                font: UIFont(
                    name: formData.fontName, size: Double(formData.popupStyleThemes.mediumTextSize)
                ),
                textColor: formData.popupStyleThemes.darkColor
            ),
            headerBgColor: formData.popupStyleThemes.boxColor,
            headingThreePopupTextStyle: PopupTextStyle(
                font: {
                    let size = Double(formData.popupStyleThemes.largeTextSize)
                    if formData.popupStyleThemes.headingThreeBold {
                        return UIFont(
                            name: "Arial-BoldMT",
                            size: 14
                        )
                    } else {
                        return UIFont(
                            name: "Arial",
                            size: 14
                        )
                    }
                }(),
                textColor: formData.popupStyleThemes.primaryColor
            ),
            paragraphPopupTextStyle: PopupTextStyle(
                font: UIFont(
                    name: formData.fontName, size: Double(formData.popupStyleThemes.smallTextSize)
                ),
                textColor: formData.popupStyleThemes.lightColor
            ),
            connectorPopupTextStyle: PopupTextStyle(
                font: UIFont(
                    name: formData.fontName, size: Double(formData.popupStyleThemes.largeTextSize)
                ),
                textColor: formData.popupStyleThemes.darkColor
            ),
            disclosurePopupTextStyle: PopupTextStyle(
                font: UIFont(
                    name: formData.fontName, size: Double(formData.popupStyleThemes.smallTextSize)
                ),
                textColor: formData.popupStyleThemes.lightColor
            ),
            actionButtonStyle: PopupActionButtonStyle(
                font: UIFont(
                    name: formData.fontName, size: Double(formData.popupStyleThemes.mediumTextSize)
                ),
                textColor: .white,
                backgroundColor: formData.popupStyleThemes.buttonBackgroundColor ?? formData.popupStyleThemes.primaryColor,
                cornerRadius: formData.popupStyleThemes.cornerRadius,
                padding: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            )
        )

        Task {
            await BreadPartnersSDK.shared.setup(
                environment: formData.sdkEnv,
                integrationKey: formData.apiKey,
                enableLog: formData.enableLog
            )

            await BreadPartnersSDK.shared.registerPlacements(
                merchantConfiguration: MerchantConfiguration(
                    buyer: createBuyer(from: formData),
                    loyaltyID: formData.loyaltyId,
                    campaignID: formData.campaignID,
                    storeNumber: formData.storeNumber,
                    departmentId: formData.departmentId,
                    cardholderTier: formData.cardholderTier,
                    env: formData.sdkEnv,
                    channel: formData.channel,
                    subchannel: formData.subchannel,
                    overrideKey: formData.overrideKey
                ),
                placementsConfiguration: PlacementConfiguration(
                    placementData: PlacementData(
                        financingType: formData.financial,
                        locationType: formData.location,
                        placementId: formData.placementId,
                        domID: "123", allowCheckout: formData.allowCheckout,
                        order: Order(
                            subTotal: CurrencyValue(
                                currency: "USD", value: Int64(formData.subTotal) ?? 0
                            ),
                            totalDiscounts: CurrencyValue(
                                currency: "USD", value: Int64(formData.totalDiscount) ?? 0
                            ),
                            totalPrice: CurrencyValue(
                                currency: "USD", value: Int64(formData.totalPrice) ?? 0
                            ),
                            totalShipping: CurrencyValue(
                                currency: "USD", value: Int64(formData.totalShipping) ?? 0
                            ),
                            totalTax: CurrencyValue(
                                currency: "USD", value: Int64(formData.totalTax) ?? 0
                            ),
                            discountCode: formData.discountCode.isEmpty ? nil : formData.discountCode,
                            pickupInformation: formData.pickupAddress1.isEmpty ? nil : PickupInformation(
                                name: Name(
                                    givenName: formData.pickupGivenName.isEmpty ? nil : formData.pickupGivenName,
                                    familyName: formData.pickupFamilyName.isEmpty ? nil : formData.pickupFamilyName,
                                    additionalName: formData.pickupAdditionalName.isEmpty ? nil : formData.pickupAdditionalName
                                ),
                                phone: formData.pickupPhone.isEmpty ? nil : formData.pickupPhone,
                                address: Address(
                                    address1: formData.pickupAddress1,
                                    address2: formData.pickupAddress2.isEmpty ? nil : formData.pickupAddress2,
                                    locality: formData.pickupLocality.isEmpty ? nil : formData.pickupLocality,
                                    postalCode: formData.pickupPostalCode.isEmpty ? nil : formData.pickupPostalCode,
                                    region: formData.pickupRegion.isEmpty ? nil : formData.pickupRegion,
                                    country: formData.pickupCountry.isEmpty ? nil : formData.pickupCountry
                                ),
                                email: formData.pickupEmail.isEmpty ? nil : formData.pickupEmail
                            ),
                            fulfillmentType: formData.fulfillmentType,
                            items: formData.items,
                            bnplEligible: formData.bnplEligible
                        ),
                        defaultSelectedCardKey: formData.defaultSelectedCardKey,
                        selectedCardKey: formData.selectedCardKey,
                        upqInSessionToken: formData.inSessionToken.isEmpty ? nil : formData.inSessionToken,
                        financingBuyerId: formData.financingBuyerId.isEmpty ? nil : formData.financingBuyerId,
                        prequalificationId: formData.prequalificationId.isEmpty ? nil : formData.prequalificationId,
                        prequalCreditLimit: formData.prequalCreditLimit.isEmpty ? nil : formData.prequalCreditLimit
                    ),
                    popUpStyling: formData.stylePopup ? popUpStyling : nil
                ),
                splitTextAndAction: formData.separateTextAndButton,
                forSwiftUI: true
            ) { event in
                DispatchQueue.main.async {
                    self.isLoading = false
                    switch event {
                    case .renderSwiftUITextViewWithLink(let textView):
                        self.textWithLinkResponse = textView
                    case .renderSwiftUISeparateTextAndButton(
                        let textView, let button
                    ):
                        self.textWithButton = (textView, button)
                    case .renderPopupView(let popupView):
                        self.overlayResponse = popupView
                    case .sdkError(let error):
                        self.logs += "\n" + error.localizedDescription
                    case .onSDKEventLog(let logs):
                        self.logs += "\n" + "\(logs)"
                    case .unifiedOffersReceived(let result):
                        if let payload = result as? [String: Any] {
                            let prequalCreditLimit = (payload["prequalCreditLimit"] as? Int64).map { String($0) } ?? ""
                            let prequalificationId = (payload["prequalificationId"] as? Int64).map { String($0) } ?? ""
                            let financingBuyerId = payload["financingBuyerId"] as? String ?? ""
                            let inSessionToken = payload["inSessionToken"] as? String ?? ""
                            onUnifiedOffersReceived?(prequalCreditLimit, prequalificationId, financingBuyerId, inSessionToken)
                        }
                    case .textClicked:
                        self.logs += "\n" + "Text Clicked"
                    default:
                        self.logs += "\n" + "BreadPartnerSDK:: \(event)"
                        break
                    }
                }
            }
        }
    }

    func rtpsCall(formData: RTPSFormData) {
        isLoading = true
        overlayResponse = nil
        error = nil
        logs = "No Logs"

        Task {
            await BreadPartnersSDK.shared.setup(
                environment: formData.sdkEnv,
                integrationKey: formData.apiKey,
                enableLog: formData.enableLog
            )
            try? await Task.sleep(nanoseconds: UInt64(1_500_000_000))

            let rtpsData1 = RTPSData(
                order: Order(
                    totalPrice: CurrencyValue(
                        currency: "USD",
                        value: Int64(formData.productAmount) ?? 0
                    )
                ),
                locationType: formData.location,
                prescreenId: formData.preScreenID.isEmpty ? nil : Int64(formData.preScreenID),
                customerAcceptedOffer: formData.customerAcceptedOffer,
                mockResponse: formData.mockTest
            )

            let placementsConfiguration2 = PlacementConfiguration(
                rtpsData: rtpsData1
            )

            let merchantConfiguration2 = MerchantConfiguration(
                buyer: BreadPartnersBuyer(
                    givenName: formData.firstName,
                    familyName: formData.lastName,
                    additionalName: formData.middleName,
                    email: formData.email,
                    phone: formData.mobile,
                    alternativePhone: formData.alternateMobile,
                    billingAddress: BreadPartnersAddress(
                        address1: formData.addressOne,
                        country: formData.country,
                        locality: formData.city,
                        region: formData.state,
                        postalCode: formData.zip
                    )
                ),
                storeNumber: formData.storeNumber,
                env: formData.sdkEnv,
                channel: formData.channel,
                subchannel: formData.subchannel
            )

            await BreadPartnersSDK.shared.silentRTPSRequest(
                merchantConfiguration: merchantConfiguration2,
                placementsConfiguration: placementsConfiguration2
            ) { event in
                DispatchQueue.main.async {
                    self.isLoading = false
                    switch event {
                    case .renderPopupView(let popupView):
                        self.overlayResponse = popupView
                    case .sdkError(let error):
                        self.logs += "\n" + error.localizedDescription
                    case .onSDKEventLog(let logs):
                        self.logs += "\n" + "\(logs)"
                    default:
                        self.logs += "\n" + "BreadPartnerSDK:: \(event)"
                        break
                    }
                }
            }
        }
    }

    func openExperienceForPlacement(formData: PlacementFormData, onUnifiedOffersReceived: ((String, String, String, String) -> Void)? = nil) {
        isLoading = true
        textWithLinkResponse = nil
        textWithButton = nil
        overlayResponse = nil
        error = nil
        logs = "No Logs"

        Task {
            await BreadPartnersSDK.shared.setup(
                environment: formData.sdkEnv,
                integrationKey: formData.apiKey,
                enableLog: formData.enableLog
            )

            await BreadPartnersSDK.shared.openExperienceForPlacement(
                merchantConfiguration: MerchantConfiguration(
                    buyer: createBuyer(from: formData),
                    loyaltyID: formData.loyaltyId,
                    campaignID: formData.campaignID,
                    storeNumber: formData.storeNumber,
                    departmentId: formData.departmentId,
                    cardholderTier: formData.cardholderTier,
                    env: formData.sdkEnv,
                    channel: formData.channel,
                    subchannel: formData.subchannel,
                    overrideKey: formData.overrideKey
                ),
                placementsConfiguration: PlacementConfiguration(
                    placementData: PlacementData(
                        financingType: formData.financial,
                        locationType: formData.location,
                        placementId: formData.placementId,
                        domID: "123", allowCheckout: formData.allowCheckout,
                        order: Order(
                            subTotal: CurrencyValue(
                                currency: "USD", value: Int64(formData.subTotal) ?? 0
                            ),
                            totalDiscounts: CurrencyValue(
                                currency: "USD", value: Int64(formData.totalDiscount) ?? 0
                            ),
                            totalPrice: CurrencyValue(
                                currency: "USD", value: Int64(formData.totalPrice) ?? 0
                            ),
                            totalShipping: CurrencyValue(
                                currency: "USD", value: Int64(formData.totalShipping) ?? 0
                            ),
                            totalTax: CurrencyValue(
                                currency: "USD", value: Int64(formData.totalTax) ?? 0
                            ),
                            discountCode: formData.discountCode.isEmpty ? nil : formData.discountCode,
                            pickupInformation: formData.pickupAddress1.isEmpty ? nil : PickupInformation(
                                name: Name(
                                    givenName: formData.pickupGivenName.isEmpty ? nil : formData.pickupGivenName,
                                    familyName: formData.pickupFamilyName.isEmpty ? nil : formData.pickupFamilyName,
                                    additionalName: formData.pickupAdditionalName.isEmpty ? nil : formData.pickupAdditionalName
                                ),
                                phone: formData.pickupPhone.isEmpty ? nil : formData.pickupPhone,
                                address: Address(
                                    address1: formData.pickupAddress1,
                                    address2: formData.pickupAddress2.isEmpty ? nil : formData.pickupAddress2,
                                    locality: formData.pickupLocality.isEmpty ? nil : formData.pickupLocality,
                                    postalCode: formData.pickupPostalCode.isEmpty ? nil : formData.pickupPostalCode,
                                    region: formData.pickupRegion.isEmpty ? nil : formData.pickupRegion,
                                    country: formData.pickupCountry.isEmpty ? nil : formData.pickupCountry
                                ),
                                email: formData.pickupEmail.isEmpty ? nil : formData.pickupEmail
                            ),
                            fulfillmentType: formData.fulfillmentType,
                            items: formData.items,
                            bnplEligible: formData.bnplEligible
                        ),
                        defaultSelectedCardKey: formData.defaultSelectedCardKey,
                        selectedCardKey: formData.selectedCardKey,
                        upqInSessionToken: formData.inSessionToken.isEmpty ? nil : formData.inSessionToken,
                        financingBuyerId: formData.financingBuyerId.isEmpty ? nil : formData.financingBuyerId,
                        prequalificationId: formData.prequalificationId.isEmpty ? nil : formData.prequalificationId,
                        prequalCreditLimit: formData.prequalCreditLimit.isEmpty ? nil : formData.prequalCreditLimit
                    )
                ),
                forSwiftUI: true
            ) { event in
                DispatchQueue.main.async {
                    self.isLoading = false
                    switch event {
                    case .renderPopupView(let popupView):
                        self.overlayResponse = popupView
                    case .sdkError(let error):
                        self.logs += "\n" + error.localizedDescription
                    case .onSDKEventLog(let logs):
                        self.logs += "\n" + "\(logs)"
                    case .unifiedOffersReceived(let result):
                        if let payload = result as? [String: Any] {
                            let prequalCreditLimit = (payload["prequalCreditLimit"] as? Int64).map { String($0) } ?? ""
                            let prequalificationId = (payload["prequalificationId"] as? Int64).map { String($0) } ?? ""
                            let financingBuyerId = payload["financingBuyerId"] as? String ?? ""
                            let inSessionToken = payload["inSessionToken"] as? String ?? ""
                            onUnifiedOffersReceived?(prequalCreditLimit, prequalificationId, financingBuyerId, inSessionToken)
                        }
                    default:
                        self.logs += "\n" + "BreadPartnerSDK:: \(event)"
                        break
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Create BreadPartnersBuyer from form data
    private func createBuyer(from formData: PlacementFormData) -> BreadPartnersBuyer? {
        // Only create buyer if at least one field is filled
        let hasData = !formData.buyerGivenName.isEmpty ||
                     !formData.buyerFamilyName.isEmpty ||
                     !formData.buyerEmail.isEmpty ||
                     !formData.buyerPhone.isEmpty ||
                     !formData.billingAddress1.isEmpty ||
                     !formData.shippingAddress1.isEmpty
        
        guard hasData else { return nil }
        
        // Create billing address if address1 is provided
        let billingAddress: BreadPartnersAddress? = !formData.billingAddress1.isEmpty
            ? BreadPartnersAddress(
                address1: formData.billingAddress1,
                address2: formData.billingAddress2.isEmpty ? nil : formData.billingAddress2,
                country: formData.billingCountry.isEmpty ? nil : formData.billingCountry,
                locality: formData.billingLocality.isEmpty ? nil : formData.billingLocality,
                region: formData.billingRegion.isEmpty ? nil : formData.billingRegion,
                postalCode: formData.billingPostalCode.isEmpty ? nil : formData.billingPostalCode
            )
            : nil
        
        // Create shipping address if address1 is provided
        let shippingAddress: BreadPartnersAddress? = !formData.shippingAddress1.isEmpty
            ? BreadPartnersAddress(
                address1: formData.shippingAddress1,
                address2: formData.shippingAddress2.isEmpty ? nil : formData.shippingAddress2,
                country: formData.shippingCountry.isEmpty ? nil : formData.shippingCountry,
                locality: formData.shippingLocality.isEmpty ? nil : formData.shippingLocality,
                region: formData.shippingRegion.isEmpty ? nil : formData.shippingRegion,
                postalCode: formData.shippingPostalCode.isEmpty ? nil : formData.shippingPostalCode
            )
            : nil
        
        return BreadPartnersBuyer(
            givenName: formData.buyerGivenName.isEmpty ? nil : formData.buyerGivenName,
            familyName: formData.buyerFamilyName.isEmpty ? nil : formData.buyerFamilyName,
            additionalName: formData.buyerAdditionalName.isEmpty ? nil : formData.buyerAdditionalName,
            birthDate: formData.buyerBirthDate.isEmpty ? nil : formData.buyerBirthDate,
            email: formData.buyerEmail.isEmpty ? nil : formData.buyerEmail,
            phone: formData.buyerPhone.isEmpty ? nil : formData.buyerPhone,
            alternativePhone: formData.buyerAlternativePhone.isEmpty ? nil : formData.buyerAlternativePhone,
            billingAddress: billingAddress,
            shippingAddress: shippingAddress
        )
    }
}
