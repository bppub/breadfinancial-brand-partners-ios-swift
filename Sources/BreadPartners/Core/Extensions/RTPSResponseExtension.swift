//------------------------------------------------------------------------------
//  File:          RTPSResponseExtension.swift
//  Author(s):     Bread Financial
//  Date:          17 March 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing extension methods for mapping RTPSResponse data to configuration
//  objects.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Foundation

extension RTPSResponse {
    /// Updates a MerchantConfiguration with buyer information from the RTPS response.
    ///
    /// This method creates an updated copy of the merchant configuration with buyer
    /// information populated from the account lookup API response.
    ///
    /// - Parameter merchantConfiguration: The original merchant configuration.
    /// - Returns: An updated MerchantConfiguration with buyer data from the response.
    func updateMerchantConfiguration(_ merchantConfiguration: MerchantConfiguration) -> MerchantConfiguration {
        var updatedConfig = merchantConfiguration

        // Create or update buyer information
        var buyer = updatedConfig.buyer ?? BreadPartnersBuyer()

        if let firstName = self.firstName {
            buyer.givenName = firstName
        }

        if let lastName = self.lastName {
            buyer.familyName = lastName
        }

        if let middleInitial = self.middleInitial {
            buyer.additionalName = middleInitial
        }

        // Create or update billing address
        if address1 != nil || city != nil || state != nil || zip != nil {
            var billingAddress = buyer.billingAddress ?? BreadPartnersAddress(address1: "")

            if let address1 = self.address1 {
                billingAddress.address1 = address1
            }

            if let address2 = self.address2 {
                billingAddress.address2 = address2
            }

            if let city = self.city {
                billingAddress.locality = city
            }

            if let state = self.state {
                billingAddress.region = state
            }

            if let zip = self.zip {
                billingAddress.postalCode = zip
            }

            buyer.billingAddress = billingAddress
        }

        updatedConfig.buyer = buyer

        return updatedConfig
    }
}
