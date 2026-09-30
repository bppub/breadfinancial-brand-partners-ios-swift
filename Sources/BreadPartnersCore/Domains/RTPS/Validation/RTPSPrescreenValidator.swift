package enum RTPSPrescreenValidator {
    /// Prescreen requires first name, last name, and a complete billing address.
    package static func hasRequiredFields(
        in merchantConfiguration: MerchantConfiguration
    ) -> Bool {
        let buyer = merchantConfiguration.buyer
        let billingAddress = buyer?.billingAddress

        guard let givenName = buyer?.givenName, !givenName.isEmpty,
            let familyName = buyer?.familyName, !familyName.isEmpty,
            let address1 = billingAddress?.address1, !address1.isEmpty,
            let country = billingAddress?.country, !country.isEmpty,
            let locality = billingAddress?.locality, !locality.isEmpty,
            let region = billingAddress?.region, !region.isEmpty,
            let postalCode = billingAddress?.postalCode, !postalCode.isEmpty
        else {
            return false
        }

        return true
    }
}
