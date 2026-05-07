//
//  CreateListingViewModel.swift
//  Market Place
//

import Foundation
import Combine
import CoreLocation
import UIKit
import Models
import Core

protocol CreateListingViewModelProtocol: ObservableObject {
    var title: String { get set }
    var description: String { get set }
    var priceText: String { get set }
    var selectedCategory: ListingCategory { get set }
    var selectedImages: [UIImage] { get set }
    var isSaving: Bool { get }
    var saveError: String? { get }
    var didSave: Bool { get set }
    var isValid: Bool { get }

    func addImage(_ image: UIImage)
    func removeImage(at index: Int)
    func saveListing()
    func reset()
}

@MainActor
final class CreateListingViewModel: CreateListingViewModelProtocol {

    @Published var title = ""
    @Published var description = ""
    @Published var priceText = ""
    @Published var selectedCategory: ListingCategory = .other
    @Published var selectedImages: [UIImage] = []
    @Published private(set) var isSaving = false
    @Published private(set) var saveError: String?
    @Published var didSave = false

    private let listingRepository: ListingRepository
    private let locationService: LocationServiceProtocol
    private let syncEngine: SyncEngineProtocol

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Double(priceText) ?? 0) > 0
    }

    init(
        listingRepository: ListingRepository,
        locationService: LocationServiceProtocol,
        syncEngine: SyncEngineProtocol
    ) {
        self.listingRepository = listingRepository
        self.locationService = locationService
        self.syncEngine = syncEngine
    }

    func addImage(_ image: UIImage) {
        guard selectedImages.count < 5 else { return }
        selectedImages.append(image)
    }

    func removeImage(at index: Int) {
        guard selectedImages.indices.contains(index) else { return }
        selectedImages.remove(at: index)
    }

    func saveListing() {
        guard isValid else { return }
        isSaving = true
        saveError = nil

        // Save images locally
        let localPaths = selectedImages.compactMap { image in
            PhotoService.shared.saveImage(image)
        }

        // Build location from current position or default
        let location: ListingLocation
        if let current = locationService.currentLocation {
            location = ListingLocation(
                latitude: current.coordinate.latitude,
                longitude: current.coordinate.longitude,
                address: "Current Location"
            )
        } else {
            location = ListingLocation(
                latitude: 37.7749,
                longitude: -122.4194,
                address: "San Francisco, CA"
            )
        }

        let draft = ListingDraft(
            title: title.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            price: Double(priceText) ?? 0,
            location: location,
            localImagePaths: localPaths,
            category: selectedCategory,
            syncStatus: .pendingUpload
        )

        // Queue for sync — works offline
        syncEngine.queueDraftUpload(draft)

        isSaving = false
        didSave = true
    }

    func reset() {
        title = ""
        description = ""
        priceText = ""
        selectedCategory = .other
        selectedImages = []
        isSaving = false
        saveError = nil
        didSave = false
    }
}
