//
//  ListingRepository.swift
//  Core
//

import Foundation
import CoreData.NSManagedObjectContext
import Models
import Networking

// MARK: - Protocol

public protocol ListingRepository {
    func getListings(forceRefresh: Bool) async throws -> [Listing]
    func getFavoritedListings() -> [Listing]
    func addFavorite(listingId: String) -> Bool
    func removeFavorite(listingId: String) -> Bool
    func saveDraft(_ draft: ListingDraft)
    func getPendingDrafts() -> [ListingDraft]
    func removeDraft(id: String)
    func updateListing(_ listing: Listing)
    func getPendingEdits() -> [Listing]
}

// MARK: - Implementation

public final class ListingRepositoryImplementation: ListingRepository {

    private let remoteDataSource: RemoteDataSourceProtocol
    private var cachedListings: [Listing] = []
    private var pendingDrafts: [ListingDraft] = []
    private let cacheTTL: TimeInterval
    private var lastFetchDate: Date?

    public init(
        remoteDataSource: RemoteDataSourceProtocol,
        cacheTTL: TimeInterval = 10 * 60
    ) {
        self.remoteDataSource = remoteDataSource
        self.cacheTTL = cacheTTL
    }

    public func getListings(forceRefresh: Bool = false) async throws -> [Listing] {

        // Check in-memory cache
        let cacheIsValid: Bool = {
            guard !forceRefresh else { return false }
            guard !cachedListings.isEmpty else { return false }
            guard let lastFetchDate else { return false }
            return Date().timeIntervalSince(lastFetchDate) < self.cacheTTL
        }()

        if cacheIsValid {
            return cachedListings
        }

        // Fetch from remote
        do {
            let remoteListings = try await remoteDataSource.fetchListings()

            mergeAndCache(remoteListings)
            lastFetchDate = Date()
            return cachedListings
        } catch {
            // Offline fallback
            if !cachedListings.isEmpty {
                return cachedListings
            }
            throw error
        }
    }

    public func getFavoritedListings() -> [Listing] {
        return cachedListings.filter { $0.isFavorited }
    }

    public func addFavorite(listingId: String) -> Bool {
        return updateFavorite(listingId: listingId, isFavorited: true)
    }

    public func removeFavorite(listingId: String) -> Bool {
        return updateFavorite(listingId: listingId, isFavorited: false)
    }

    public func saveDraft(_ draft: ListingDraft) {
        if let index = pendingDrafts.firstIndex(where: { $0.id == draft.id }) {
            pendingDrafts[index] = draft
        } else {
            pendingDrafts.append(draft)
        }
    }

    public func getPendingDrafts() -> [ListingDraft] {
        return pendingDrafts
    }

    public func removeDraft(id: String) {
        pendingDrafts.removeAll { $0.id == id }
    }

    public func updateListing(_ listing: Listing) {
        if let index = cachedListings.firstIndex(where: { $0.id == listing.id }) {
            cachedListings[index] = listing
        }
    }

    public func getPendingEdits() -> [Listing] {
        return cachedListings.filter { $0.syncStatus == .pendingEdit }
    }

    // MARK: - Private Helpers

    private func updateFavorite(listingId: String, isFavorited: Bool) -> Bool {
        guard let index = cachedListings.firstIndex(where: { $0.id == listingId }) else {
            print("No listing found with id \(listingId)")
            return false
        }
        cachedListings[index].isFavorited = isFavorited
        return true
    }

    private func mergeAndCache(_ remoteListings: [Listing]) {
        // Preserve existing favorite state when refreshing
        let favoritedIds = Set(cachedListings.filter { $0.isFavorited }.map { $0.id })
        cachedListings = remoteListings.map { listing in
            var merged = listing
            if favoritedIds.contains(listing.id) {
                merged.isFavorited = true
            }
            return merged
        }
    }

    // MARK: - Core Data Persistence

    private func fetchListingsFromCoreData() -> [Listing] {
        []
    }

    private func saveListingsToCoreData(_ listings: [Listing]) {
    }

    private func getLastUpdated(forKey key: String) -> Date? {
        nil
    }

    private func setLastUpdated(_ date: Date, forKey key: String) {
    }
}
