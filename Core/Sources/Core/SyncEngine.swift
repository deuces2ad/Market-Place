//
//  SyncEngine.swift
//  Core
//

import Foundation
import Combine
import Network
import Models
import Networking

// MARK: - Protocol

public protocol SyncEngineProtocol: AnyObject {
    var syncStatusPublisher: AnyPublisher<SyncEngineStatus, Never> { get }
    var currentStatus: SyncEngineStatus { get }
    func queueDraftUpload(_ draft: ListingDraft)
    func queueListingEdit(_ listing: Listing)
    func syncNow() async
    func retryFailed() async
}

// MARK: - Sync Engine Status

public struct SyncEngineStatus: Equatable {
    public var isOnline: Bool
    public var pendingUploads: Int
    public var pendingEdits: Int
    public var isSyncing: Bool
    public var lastSyncDate: Date?
    public var lastError: String?

    public var hasPendingWork: Bool {
        pendingUploads > 0 || pendingEdits > 0
    }

    public static let initial = SyncEngineStatus(
        isOnline: true,
        pendingUploads: 0,
        pendingEdits: 0,
        isSyncing: false
    )
}

// MARK: - Implementation

public final class SyncEngine: SyncEngineProtocol {

    private let remoteDataSource: RemoteDataSourceProtocol
    private let listingRepository: ListingRepository
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.marketplace.sync.monitor")

    private var pendingDrafts: [ListingDraft] = []
    private var pendingEditListings: [Listing] = []

    private let statusSubject = CurrentValueSubject<SyncEngineStatus, Never>(.initial)

    public var syncStatusPublisher: AnyPublisher<SyncEngineStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }

    public var currentStatus: SyncEngineStatus {
        statusSubject.value
    }

    public init(remoteDataSource: RemoteDataSourceProtocol, listingRepository: ListingRepository) {
        self.remoteDataSource = remoteDataSource
        self.listingRepository = listingRepository
        startMonitoring()
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Network Monitoring

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            var status = self.statusSubject.value
            status.isOnline = (path.status == .satisfied)
            self.statusSubject.send(status)

            // Auto-sync when coming back online
            if path.status == .satisfied && status.hasPendingWork {
                Task { await self.syncNow() }
            }
        }
        monitor.start(queue: monitorQueue)
    }

    // MARK: - Queue Operations

    public func queueDraftUpload(_ draft: ListingDraft) {
        pendingDrafts.append(draft)
        listingRepository.saveDraft(draft)
        var status = statusSubject.value
        status.pendingUploads = pendingDrafts.count
        statusSubject.send(status)

        // Try to sync immediately if online
        if statusSubject.value.isOnline {
            Task { await syncNow() }
        }
    }

    public func queueListingEdit(_ listing: Listing) {
        // Last-write-wins: replace any existing pending edit for same ID
        if let index = pendingEditListings.firstIndex(where: { $0.id == listing.id }) {
            pendingEditListings[index] = listing
        } else {
            pendingEditListings.append(listing)
        }

        var updatedListing = listing
        updatedListing.syncStatus = .pendingEdit
        listingRepository.updateListing(updatedListing)

        var status = statusSubject.value
        status.pendingEdits = pendingEditListings.count
        statusSubject.send(status)

        if statusSubject.value.isOnline {
            Task { await syncNow() }
        }
    }

    // MARK: - Sync

    public func syncNow() async {
        guard statusSubject.value.isOnline else { return }

        var status = statusSubject.value
        status.isSyncing = true
        status.lastError = nil
        statusSubject.send(status)

        // Upload pending drafts
        var failedDrafts: [ListingDraft] = []
        for draft in pendingDrafts {
            do {
                let listing = try await remoteDataSource.createListing(draft)
                listingRepository.removeDraft(id: draft.id)
                listingRepository.updateListing(listing)
            } catch {
                var failedDraft = draft
                failedDraft.syncStatus = .failed
                failedDrafts.append(failedDraft)
            }
        }
        pendingDrafts = failedDrafts

        // Upload pending edits (last-write-wins)
        var failedEdits: [Listing] = []
        for listing in pendingEditListings {
            do {
                let updated = try await remoteDataSource.updateListing(listing)
                listingRepository.updateListing(updated)
            } catch {
                var failedListing = listing
                failedListing.syncStatus = .failed
                failedEdits.append(failedListing)
            }
        }
        pendingEditListings = failedEdits

        status = statusSubject.value
        status.isSyncing = false
        status.pendingUploads = pendingDrafts.count
        status.pendingEdits = pendingEditListings.count
        status.lastSyncDate = Date()
        if !failedDrafts.isEmpty || !failedEdits.isEmpty {
            status.lastError = "Some items failed to sync"
        }
        statusSubject.send(status)
    }

    public func retryFailed() async {
        // Move failed drafts back to pending
        for i in pendingDrafts.indices {
            pendingDrafts[i].syncStatus = .pendingUpload
        }
        for i in pendingEditListings.indices {
            pendingEditListings[i].syncStatus = .pendingEdit
        }
        await syncNow()
    }
}
