import Foundation
import Testing
@testable import BreadPartnersCore

@Suite struct RTPSResponseTests {
    @Test
    func updatesBuyerAndCreatesBillingAddressFromResponse() {
        let response = RTPSResponse(
            firstName: "Ada",
            middleInitial: "L",
            lastName: "Lovelace",
            address1: "1 Main St",
            address2: "Suite 2",
            city: "Columbus",
            state: "OH",
            zip: "43004"
        )
        let configuration = MerchantConfiguration(
            loyaltyID: "loyalty-id",
            storeNumber: "store-number",
            departmentId: "department-id"
        )

        let updatedConfiguration = response.updateMerchantConfiguration(configuration)

        #expect(updatedConfiguration.buyer?.givenName == "Ada")
        #expect(updatedConfiguration.buyer?.additionalName == "L")
        #expect(updatedConfiguration.buyer?.familyName == "Lovelace")
        #expect(updatedConfiguration.buyer?.billingAddress?.address1 == "1 Main St")
        #expect(updatedConfiguration.buyer?.billingAddress?.address2 == "Suite 2")
        #expect(updatedConfiguration.buyer?.billingAddress?.locality == "Columbus")
        #expect(updatedConfiguration.buyer?.billingAddress?.region == "OH")
        #expect(updatedConfiguration.buyer?.billingAddress?.postalCode == "43004")
    }

    @Test
    func updatesOnlyProvidedBuyerAndAddressValues() {
        let response = RTPSResponse(
            firstName: "Updated",
            address2: "New Suite",
            zip: "43005"
        )
        let configuration = MerchantConfiguration(
            buyer: BreadPartnersBuyer(
                givenName: "Original",
                familyName: "Name",
                email: "ada@example.com",
                billingAddress: BreadPartnersAddress(
                    address1: "Original Address",
                    locality: "Columbus",
                    region: "OH",
                    postalCode: "43004"
                )
            )
        )

        let updatedConfiguration = response.updateMerchantConfiguration(configuration)

        #expect(updatedConfiguration.buyer?.givenName == "Updated")
        #expect(updatedConfiguration.buyer?.familyName == "Name")
        #expect(updatedConfiguration.buyer?.email == "ada@example.com")
        #expect(updatedConfiguration.buyer?.billingAddress?.address1 == "Original Address")
        #expect(updatedConfiguration.buyer?.billingAddress?.address2 == "New Suite")
        #expect(updatedConfiguration.buyer?.billingAddress?.locality == "Columbus")
        #expect(updatedConfiguration.buyer?.billingAddress?.region == "OH")
        #expect(updatedConfiguration.buyer?.billingAddress?.postalCode == "43005")
    }

    @Test
    func preservesUnrelatedMerchantConfigurationFields() {
        let response = RTPSResponse(firstName: "Updated")
        let configuration = MerchantConfiguration(
            loyaltyID: "loyalty-id",
            campaignID: "campaign-id",
            storeNumber: "store-number",
            departmentId: "department-id",
            existingCardHolder: true,
            cardholderTier: "tier",
            env: .uat,
            cardEnv: "card-env",
            channel: "channel",
            subchannel: "subchannel",
            clerkId: "clerk-id",
            overrideKey: "override-key",
            clientVariable1: "one",
            clientVariable2: "two",
            clientVariable3: "three",
            clientVariable4: "four",
            accountId: "account-id",
            applicationId: "application-id",
            invoiceNumber: "invoice-number",
            paymentMode: .split,
            providerConfig: ["key": Data("value".utf8)],
            skipVerification: true,
            custom: ["custom": "value"],
            cardChoiceCode: "card-choice"
        )

        let updatedConfiguration = response.updateMerchantConfiguration(configuration)

        #expect(updatedConfiguration.loyaltyID == configuration.loyaltyID)
        #expect(updatedConfiguration.campaignID == configuration.campaignID)
        #expect(updatedConfiguration.storeNumber == configuration.storeNumber)
        #expect(updatedConfiguration.departmentId == configuration.departmentId)
        #expect(updatedConfiguration.existingCardHolder == configuration.existingCardHolder)
        #expect(updatedConfiguration.cardholderTier == configuration.cardholderTier)
        #expect(updatedConfiguration.env == configuration.env)
        #expect(updatedConfiguration.cardEnv == configuration.cardEnv)
        #expect(updatedConfiguration.channel == configuration.channel)
        #expect(updatedConfiguration.subchannel == configuration.subchannel)
        #expect(updatedConfiguration.clerkId == configuration.clerkId)
        #expect(updatedConfiguration.overrideKey == configuration.overrideKey)
        #expect(updatedConfiguration.clientVariable1 == configuration.clientVariable1)
        #expect(updatedConfiguration.clientVariable2 == configuration.clientVariable2)
        #expect(updatedConfiguration.clientVariable3 == configuration.clientVariable3)
        #expect(updatedConfiguration.clientVariable4 == configuration.clientVariable4)
        #expect(updatedConfiguration.accountId == configuration.accountId)
        #expect(updatedConfiguration.applicationId == configuration.applicationId)
        #expect(updatedConfiguration.invoiceNumber == configuration.invoiceNumber)
        #expect(updatedConfiguration.paymentMode == configuration.paymentMode)
        #expect(updatedConfiguration.providerConfig == configuration.providerConfig)
        #expect(updatedConfiguration.skipVerification == configuration.skipVerification)
        #expect(updatedConfiguration.custom?["custom"] as? String == "value")
        #expect(updatedConfiguration.cardChoiceCode == configuration.cardChoiceCode)
    }

    @Test
    func initializesAllResponseProperties() {
        let response = RTPSResponse(
            returnCode: "01",
            prescreenId: 42,
            firstName: "Ada",
            middleInitial: "L",
            lastName: "Lovelace",
            address1: "1 Main St",
            address2: "Suite 2",
            city: "Columbus",
            state: "OH",
            zip: "43004",
            cardType: "storeCard",
            isExpired: false,
            hasExistingAccount: true,
            errorMessage: "message",
            errorCode: 7
        )

        #expect(response.returnCode == "01")
        #expect(response.prescreenId == 42)
        #expect(response.firstName == "Ada")
        #expect(response.middleInitial == "L")
        #expect(response.lastName == "Lovelace")
        #expect(response.address1 == "1 Main St")
        #expect(response.address2 == "Suite 2")
        #expect(response.city == "Columbus")
        #expect(response.state == "OH")
        #expect(response.zip == "43004")
        #expect(response.cardType == "storeCard")
        #expect(response.isExpired == false)
        #expect(response.hasExistingAccount == true)
        #expect(response.errorMessage == "message")
        #expect(response.errorCode == 7)
    }

    @Test
    func decodesStringReturnCodeAndInt64PrescreenId() throws {
        let response = try JSONDecoder().decode(
            RTPSResponse.self,
            from: Data(#"{"returnCode":"01","prescreenId":9876543210}"#.utf8)
        )

        #expect(response.returnCode == "01")
        #expect(response.prescreenId == 9_876_543_210)
    }

    @Test
    func decodesIntegerReturnCode() throws {
        let response = try JSONDecoder().decode(
            RTPSResponse.self,
            from: Data(#"{"returnCode":0}"#.utf8)
        )

        #expect(response.returnCode == "0")
    }

    @Test
    func setsReturnCodeToNilForUnsupportedType() throws {
        let response = try JSONDecoder().decode(
            RTPSResponse.self,
            from: Data(#"{"returnCode":true}"#.utf8)
        )

        #expect(response.returnCode == nil)
    }
}
