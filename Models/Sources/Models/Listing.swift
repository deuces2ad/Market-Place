//
//  Listing.swift
//  Models
//

import Foundation
import CoreLocation

// MARK: - Listing Location

public struct ListingLocation: Codable, Equatable, Hashable {
    public let latitude: Double
    public let longitude: Double
    public let address: String

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    public var clLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    public init(latitude: Double, longitude: Double, address: String) {
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
    }
}

// MARK: - Listing

public struct Listing: Identifiable, Codable, Equatable, Hashable {
    public let id: String
    public let title: String
    public let description: String
    public let price: Double
    public let location: ListingLocation
    public let postedDate: Date
    public let imageUrls: [String]
    public let category: ListingCategory
    public let sellerName: String
    public var isFavorited: Bool
    public var syncStatus: SyncStatus

    public init(
        id: String,
        title: String,
        description: String,
        price: Double,
        location: ListingLocation,
        postedDate: Date,
        imageUrls: [String],
        category: ListingCategory,
        sellerName: String,
        isFavorited: Bool = false,
        syncStatus: SyncStatus = .synced
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.price = price
        self.location = location
        self.postedDate = postedDate
        self.imageUrls = imageUrls
        self.category = category
        self.sellerName = sellerName
        self.isFavorited = isFavorited
        self.syncStatus = syncStatus
    }
}

// MARK: - Listing Category

public enum ListingCategory: String, Codable, CaseIterable {
    case electronics = "Electronics"
    case furniture = "Furniture"
    case clothing = "Clothing"
    case other = "Other"

    public var systemImage: String {
        switch self {
        case .electronics: return "desktopcomputer"
        case .furniture: return "sofa"
        case .clothing: return "tshirt"
        case .other: return "tag"
        }
    }
}

// MARK: - Sync Status

public enum SyncStatus: String, Codable, Equatable, Hashable {
    case synced = "Synced"
    case pendingUpload = "Pending Upload"
    case pendingEdit = "Pending Edit"
    case uploading = "Uploading"
    case failed = "Failed"

    public var systemImage: String {
        switch self {
        case .synced: return "checkmark.icloud"
        case .pendingUpload: return "icloud.and.arrow.up"
        case .pendingEdit: return "pencil.circle"
        case .uploading: return "arrow.clockwise.icloud"
        case .failed: return "exclamationmark.icloud"
        }
    }
}

// MARK: - Listing Draft (for offline creation)

public struct ListingDraft: Identifiable, Codable, Equatable, Hashable {
    public let id: String
    public var title: String
    public var description: String
    public var price: Double
    public var location: ListingLocation?
    public var localImagePaths: [String]
    public var category: ListingCategory
    public var createdDate: Date
    public var syncStatus: SyncStatus

    public init(
        id: String = UUID().uuidString,
        title: String = "",
        description: String = "",
        price: Double = 0,
        location: ListingLocation? = nil,
        localImagePaths: [String] = [],
        category: ListingCategory = .other,
        createdDate: Date = Date(),
        syncStatus: SyncStatus = .pendingUpload
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.price = price
        self.location = location
        self.localImagePaths = localImagePaths
        self.category = category
        self.createdDate = createdDate
        self.syncStatus = syncStatus
    }
}
