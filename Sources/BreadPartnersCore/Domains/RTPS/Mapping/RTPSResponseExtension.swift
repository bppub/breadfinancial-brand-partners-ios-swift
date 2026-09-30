import Foundation

extension RTPSResponse {
    /// Updates a MerchantConfiguration with buyer information from the RTPS response.
    package func updateMerchantConfiguration(
        _ merchantConfiguration: MerchantConfiguration
    ) -> MerchantConfiguration {
        var updatedConfig = merchantConfiguration
        var buyer = updatedConfig.buyer ?? BreadPartnersBuyer()

        if let firstName {
            buyer.givenName = firstName
        }

        if let lastName {
            buyer.familyName = lastName
        }

        if let middleInitial {
            buyer.additionalName = middleInitial
        }

        if address1 != nil || city != nil || state != nil || zip != nil {
            var billingAddress = buyer.billingAddress ?? BreadPartnersAddress(address1: "")

            if let address1 {
                billingAddress.address1 = address1
            }

            if let address2 {
                billingAddress.address2 = address2
            }

            if let city {
                billingAddress.locality = city
            }

            if let state {
                billingAddress.region = state
            }

            if let zip {
                billingAddress.postalCode = zip
            }

            buyer.billingAddress = billingAddress
        }

        updatedConfig.buyer = buyer
        return updatedConfig
    }
}