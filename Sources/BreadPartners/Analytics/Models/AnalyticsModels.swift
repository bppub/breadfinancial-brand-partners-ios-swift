//------------------------------------------------------------------------------
//  File:          AnalyticsModels.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

import Foundation

internal enum Analytics {

    struct PlacementContent: Codable {
        let id: String?
        let contentType: String?
        let metadata: MetadataModel?
    }

    struct Placement: Codable {
        let id: String?
        let placementContentId: String?
        let overlayContentId: String?
    }

    struct EventProperties: Codable {
        let placement: Placement?
        let placementContent: PlacementContent?
        let metadata: [String: String?]?
        let actionTarget: String?
    }

    struct Props: Codable {
        let eventProperties: EventProperties?
        let userProperties: [String: String]?
    }

    struct BrowserCtx: Codable {
        let library: Library?
        let userAgent: String?
        let page: Page?
    }

    struct Library: Codable {
        let name: String?
        let version: String?
    }

    struct Page: Codable {
        let path: String?
        let url: String?
    }

    struct TrackingInfo: Codable {
        let userTrackingId: String?
        let sessionTrackingId: String?
    }

    struct Context: Codable {
        let timestamp: String?
        let apiKey: String?
        let browserCtx: BrowserCtx?
        let trackingInfo: TrackingInfo?
    }

    struct Payload: Codable {
        let name: String?
        let props: Props?
        let context: Context?
    }
}
