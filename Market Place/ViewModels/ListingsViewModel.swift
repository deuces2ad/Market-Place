//
//  ListingsViewModel.swift
//  Market Place
//

import Foundation
import Combine
import CoreLocation
import Models
import Core

public protocol ListingsViewModelProtocol: ObservableObject {
    var listings: [Listing] { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var searchText: String { get set }
    var selectedCategory: ListingCategory? { get set }
    var filteredListings: [Listing] { get }

    func loadListings(forceRefresh: Bool) async
    func refresh() async
    func toggleFavorite(for listing: Listing)
    func distance(to listing: Listing) -> CLLocationDistance?
    func formattedDistance(to listing: Listing) -> String
}

@MainActor
final class ListingsViewModel: ListingsViewModelProtocol {

    @Published
    private(set) var listings: [Listing] = []
    @Published
    private(set) var isLoading = false
    @Published
    private(set) var errorMessage: String?
    @Published
    var searchText = ""
    @Published
    var selectedCategory: ListingCategory?

    // MARK: - Dependencies

    private let listingRepository: ListingRepository
    private let locationService: LocationServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    var filteredListings: [Listing] {
        var result = listings

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query) ||
                $0.location.address.lowercased().contains(query) ||
                $0.category.rawValue.lowercased().contains(query) ||
                $0.sellerName.lowercased().contains(query)
            }
        }

        return result
    }

    init(listingRepository: ListingRepository, locationService: LocationServiceProtocol) {
        self.listingRepository = listingRepository
        self.locationService = locationService
        observeLocation()
    }

    func loadListings(forceRefresh: Bool = false) async {
        isLoading = true
        errorMessage = nil

        do {
            let fetched = try await listingRepository.getListings(forceRefresh: forceRefresh)
            listings = sortedByDistance(fetched)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        await loadListings(forceRefresh: true)
    }

    // MARK: - Favorites

    func toggleFavorite(for listing: Listing) {
        if listing.isFavorited {
            _ = listingRepository.removeFavorite(listingId: listing.id)
        } else {
            _ = listingRepository.addFavorite(listingId: listing.id)
        }

        if let index = listings.firstIndex(where: { $0.id == listing.id }) {
            listings[index].isFavorited = !listing.isFavorited
        }
    }

    func distance(to listing: Listing) -> CLLocationDistance? {
        locationService.distance(to: listing.location.coordinate)
    }

    func formattedDistance(to listing: Listing) -> String {
        Formatters.formattedDistance(distance(to: listing))
    }

    private func sortedByDistance(_ listings: [Listing]) -> [Listing] {
        guard locationService.currentLocation != nil else { return listings }
        return listings.sorted { a, b in
            let dA = distance(to: a) ?? .greatestFiniteMagnitude
            let dB = distance(to: b) ?? .greatestFiniteMagnitude
            return dA < dB
        }
    }

    private func observeLocation() {
        locationService.locationPublisher
            .compactMap { $0 }
            .removeDuplicates(by: { $0.distance(from: $1) < 50 })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                let sorted = self.sortedByDistance(self.listings)
                if sorted.map(\.id) != self.listings.map(\.id) {
                    self.listings = sorted
                }
            }
            .store(in: &cancellables)
    }
}
