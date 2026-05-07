//
//  RemoteDataSource.swift
//  Networking
//

import Foundation
import Models

// MARK: - Protocol

public protocol RemoteDataSourceProtocol {
    func fetchListings() async throws -> [Listing]
    func createListing(_ draft: ListingDraft) async throws -> Listing
    func updateListing(_ listing: Listing) async throws -> Listing
    func uploadImage(data: Data) async throws -> String
}

// MARK: - Network Errors

public enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingFailed(Error)
    case serverError(Int)
    case noConnection

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid server response"
        case .decodingFailed(let error): return "Decoding failed: \(error.localizedDescription)"
        case .serverError(let code): return "Server error: \(code)"
        case .noConnection: return "No internet connection"
        }
    }
}

// MARK: - Implementation

public final class RemoteDataSource: RemoteDataSourceProtocol {

    private static let baseImageURL = "https://images.unsplash.com/photo-"

    public init() {}

    public func fetchListings() async throws -> [Listing] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return Self.sampleListings
    }

    public func createListing(_ draft: ListingDraft) async throws -> Listing {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return Listing(
            id: draft.id,
            title: draft.title,
            description: draft.description,
            price: draft.price,
            location: draft.location ?? ListingLocation(latitude: 37.7749, longitude: -122.4194, address: "San Francisco, CA"),
            postedDate: draft.createdDate,
            imageUrls: draft.localImagePaths,
            category: draft.category,
            sellerName: "You",
            syncStatus: .synced
        )
    }

    public func updateListing(_ listing: Listing) async throws -> Listing {
        try await Task.sleep(nanoseconds: 800_000_000)
        var updated = listing
        updated.syncStatus = .synced
        return updated
    }

    public func uploadImage(data: Data) async throws -> String {
        try await Task.sleep(nanoseconds: 1_500_000_000)
        return "\(Self.baseImageURL)\(UUID().uuidString)?w=800&h=600"
    }

    // MARK: - Sample Data

    private static let sampleListings: [Listing] = {
        let now = Date()
        let cal = Calendar.current

        return [
            Listing(
                id: "1",
                title: "MacBook Pro 14\" M3",
                description: "Like new MacBook Pro 14-inch with M3 chip, 16GB RAM, 512GB SSD. Includes original box and charger. Battery cycle count under 50.",
                price: 1499.00,
                location: ListingLocation(latitude: 37.7749, longitude: -122.4194, address: "Mission District, SF"),
                postedDate: cal.date(byAdding: .hour, value: -2, to: now)!,
                imageUrls: ["\(baseImageURL)1517336714731-489689fd1ca8?w=800&h=600"],
                category: .electronics,
                sellerName: "Alex"
            ),
            Listing(
                id: "2",
                title: "Mid-Century Modern Sofa",
                description: "Beautiful walnut frame sofa with teal cushions. Seats 3 comfortably. Minor wear on armrests. Must pick up.",
                price: 350.00,
                location: ListingLocation(latitude: 37.7849, longitude: -122.4094, address: "SoMa, SF"),
                postedDate: cal.date(byAdding: .hour, value: -5, to: now)!,
                imageUrls: ["\(baseImageURL)1555041469-a586c61ea9bc?w=800&h=600"],
                category: .furniture,
                sellerName: "Jordan"
            ),
            Listing(
                id: "3",
                title: "Vintage Leather Jacket",
                description: "Genuine leather bomber jacket, size M. Broken in perfectly. Classic brown color with quilted lining.",
                price: 120.00,
                location: ListingLocation(latitude: 37.7859, longitude: -122.4009, address: "Hayes Valley, SF"),
                postedDate: cal.date(byAdding: .day, value: -1, to: now)!,
                imageUrls: ["\(baseImageURL)1551028719-00167b16eac5?w=800&h=600"],
                category: .clothing,
                sellerName: "Sam"
            ),
            Listing(
                id: "4",
                title: "Trek Mountain Bike",
                description: "Trek Marlin 7, 29\" wheels, hydraulic disc brakes. Great for trails and commuting. Recently tuned up.",
                price: 650.00,
                location: ListingLocation(latitude: 37.8070, longitude: -122.4190, address: "Marina District, SF"),
                postedDate: cal.date(byAdding: .hour, value: -18, to: now)!,
                imageUrls: ["\(baseImageURL)1507035895480-2b3156c31fc8?w=800&h=600"],
                category: .sports,
                sellerName: "Chris"
            ),
            Listing(
                id: "5",
                title: "IKEA KALLAX Shelf Unit",
                description: "White 4x4 KALLAX shelf unit. Perfect condition. Includes 4 drawer inserts. Disassembled for easy transport.",
                price: 80.00,
                location: ListingLocation(latitude: 37.7879, longitude: -122.3964, address: "Potrero Hill, SF"),
                postedDate: cal.date(byAdding: .day, value: -2, to: now)!,
                imageUrls: ["\(baseImageURL)1532372320572-cda25653a26d?w=800&h=600"],
                category: .homeGarden,
                sellerName: "Taylor"
            ),
        ]
    }()
}
