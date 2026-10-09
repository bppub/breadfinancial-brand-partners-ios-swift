//------------------------------------------------------------------------------
//  File:          PlacementContentResolver.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import BreadPartnersCore

struct PlacementContentResolver {
    func overlayHTMLContent(in response: PlacementsResponse) -> String? {
        guard
            let content = response.placementContent?.first(where: {
                $0.metadata?.templateId?.contains("overlay") == true
            })
        else {
            return nil
        }

        return content.contentData?.htmlContent ?? ""
    }
}
