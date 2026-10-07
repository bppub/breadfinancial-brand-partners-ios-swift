//------------------------------------------------------------------------------
//  File:          UPQMapper.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Foundation

package struct UPQMapper: Sendable {
    package init() {}

    package func mapCommonData(
        placementData: PlacementData? = nil,
        merchantConfiguration: MerchantConfiguration? = nil,
        sessionId: String? = nil,
        userTrackingId: String? = nil
    ) -> [String: Any?] {
        var data: [String: Any?] = [:]

        data.assignDefined([
            "firstName": merchantConfiguration?.buyer?.givenName,
            "lastName": merchantConfiguration?.buyer?.familyName,
            "address1": merchantConfiguration?.buyer?.billingAddress?.address1,
            "address2": merchantConfiguration?.buyer?.billingAddress?.address2,
            "city": merchantConfiguration?.buyer?.billingAddress?.locality,
            "state": merchantConfiguration?.buyer?.billingAddress?.region,
            "zip": merchantConfiguration?.buyer?.billingAddress?.postalCode,
            "emailAddress": merchantConfiguration?.buyer?.email,
            "mobilePhone": merchantConfiguration?.buyer?.phone,
            "alternativePhone": merchantConfiguration?.buyer?.alternativePhone,
            "storeNumber": merchantConfiguration?.storeNumber,
            "loyaltyNumber": merchantConfiguration?.loyaltyID,
            "departmentId": merchantConfiguration?.departmentId,
            "checkoutAmount": placementData?.order?.totalPrice?.value.map { fromMoneyToDollars($0) as Any },
            "location": placementData?.locationType?.rawValue,
            "epId": userTrackingId,
            "epPlacementId": placementData?.placementId,
            "epSessionId": sessionId,
            "channel": merchantConfiguration?.channel,
            "subchannel": merchantConfiguration?.subchannel,
            "clientVariable1": merchantConfiguration?.clientVariable1,
            "clientVariable2": merchantConfiguration?.clientVariable2,
            "clientVariable3": merchantConfiguration?.clientVariable3,
            "clientVariable4": merchantConfiguration?.clientVariable4,
            "selectedCardKey": placementData?.selectedCardKey,
            "defaultSelectedCardKey": placementData?.defaultSelectedCardKey,
            "overrideKey": merchantConfiguration?.overrideKey,
            "cardChoiceCode": merchantConfiguration?.cardChoiceCode,
            "associateId": merchantConfiguration?.clerkId,
            "splitPayment": merchantConfiguration?.paymentMode == .split ? true : nil,
        ])

        return data
    }

    package func mapShippingAddress(buyer: BreadPartnersBuyer?) -> [String: Any?]? {
        guard let address = buyer?.shippingAddress else { return nil }

        var data: [String: Any?] = [:]

        data.assignDefined([
            "address1": address.address1,
            "address2": address.address2,
            "city": address.locality,
            "state": address.region,
            "zip": address.postalCode,
        ])

        return data
    }

    package func mapOrder(_ order: Order?) -> [String: Any?] {
        guard let order else { return [:] }

        var data: [String: Any?] = [:]

        data.assignDefined([
            "bnplEligible": order.bnplEligible,
            "subTotalValue": fromMoneyToDollars(order.subTotal?.value),
            "totalDiscountsValue": fromMoneyToDollars(order.totalDiscounts?.value),
            "totalPriceValue": fromMoneyToDollars(order.totalPrice?.value),
            "totalShippingValue": fromMoneyToDollars(order.totalShipping?.value),
            "totalTaxValue": fromMoneyToDollars(order.totalTax?.value),
            "fulfillmentType": order.fulfillmentType?.rawValue,
        ])

        if let items = order.items {
            let mappedItems = items.map { item in
                var itemData: [String: Any?] = [:]
                return itemData.assignDefined([
                    "name": item.name,
                    "category": item.category,
                    "quantity": item.quantity,
                    "unitPriceValue": fromMoneyToDollars(item.unitPrice?.value),
                    "unitTaxValue": fromMoneyToDollars(item.unitTax?.value),
                    "sku": item.sku,
                    "shippingCostValue": fromMoneyToDollars(item.shippingCost?.value),
                    "fulfillmentType": item.fulfillmentType?.rawValue,
                ])
            }
            if !mappedItems.isEmpty {
                data["items"] = mappedItems
            }
        }

        if let pickup = order.pickupInformation {
            var pickupData: [String: Any?] = [:]

            if let name = pickup.name {
                var nameData: [String: Any?] = [:]
                nameData.assignDefined([
                    "firstName": name.givenName,
                    "lastName": name.familyName,
                    "additionalName": name.additionalName,
                ])
                pickupData["name"] = nameData
            }

            if let address = pickup.address {
                var addressData: [String: Any?] = [:]
                addressData.assignDefined([
                    "address1": address.address1,
                    "address2": address.address2,
                    "city": address.locality,
                    "state": address.region,
                    "zip": address.postalCode,
                ])
                pickupData["address"] = addressData
            }

            data["pickupInformation"] = pickupData.assignDefined([
                "mobilePhone": pickup.phone,
                "emailAddress": pickup.email,
            ])
        }

        return data
    }

    package func applyBNPLEligibility(_ order: inout [String: Any?]) {
        guard !order.isEmpty else { return }

        guard let items = order["items"] as? [[String: Any?]] else { return }

        for item in items {
            if let category = (item["category"] as? String)?.lowercased(),
                ineligibleItemCategories.contains(category)
            {
                order["bnplEligible"] = false
                return
            }
        }
    }

    package func mapCheckoutData(
        placementData: PlacementData? = nil,
        merchantConfiguration: MerchantConfiguration? = nil,
        sessionTrackingId: String? = nil,
        userTrackingId: String? = nil,
        financingLocationId: String? = nil,
        callCenter: String? = nil
    ) -> [String: Any?] {
        var data = mapCommonData(
            placementData: placementData,
            merchantConfiguration: merchantConfiguration,
            sessionId: sessionTrackingId,
            userTrackingId: userTrackingId
        )

        var order = mapOrder(placementData?.order)

        applyBNPLEligibility(&order)

        return data.assignDefined([
            "order": order,
            "shippingAddress": mapShippingAddress(buyer: merchantConfiguration?.buyer),
            "prequalCreditLimit": placementData?.prequalCreditLimit,
            "prequalificationId": placementData?.prequalificationId,
            "financingBuyerId": placementData?.financingBuyerId,
            "financingLocationId": financingLocationId,
            "callCenter": callCenter,
            "inSessionToken": placementData?.upqInSessionToken,
        ])
    }

    package func offerQueryParams(initialData: [String: Any?], clientKey: String) -> [String: Any?] {
        var queryParams: [String: Any?] = ["embedded": true, "clientKey": clientKey]

        queryParams.merge(initialData) { _, new in new }

        return queryParams
    }

    package func checkoutQueryParams(initialData: [String: Any?], clientKey: String) -> [String: Any?] {
        var queryParams: [String: Any?] = ["embedded": true, "clientKey": clientKey]

        queryParams.merge(initialData) { _, new in new }

        var finalParams = queryParams

        if let order = queryParams["order"] {
            finalParams["order"] = stringifyJSON(order as Any)
        }

        if let address = queryParams["shippingAddress"] {
            finalParams["shippingAddress"] = stringifyJSON(address as Any)
        }

        return finalParams
    }
}
