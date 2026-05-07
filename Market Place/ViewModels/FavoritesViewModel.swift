//
//  FavoritesViewModel.swift
//  Market Place
//

import Foundation
import Combine
import CoreLocation
import Models
import Core

protocol FavoritesViewModelProtocol: ObservableObject {
    var favoritedListings: [Listing] { get }
    var isLoading: Bool { get }

    func loadFavorites()
    func removeFavorite(for listing: Listing)
    func distance(to listing: Listing) -> CLLocationDistance?
    func formattedDistance(to listing: Listing) -> String
}

@MainActor
final class FavoritesViewModel: FavoritesViewModelProtocol {

    @Published private(set) var favoritedListings: [Listing] = []
    @Published private(set) var isLoading = false

    private let listingRepository: ListingRepository
    private let locationService: LocationServiceProtocol

    init(listingRepository: ListingRepository, locationService: LocationServiceProtocol) {
        self.listingRepository = listingRepository
        self.locationService = locationService
    }

    func loadFavorites() {
        isLoading = true
        favoritedListings = listingRepository.getFavoritedListings()
        isLoading = false
    }

    func removeFavorite(for listing: Listing) {
        _ = listingRepository.removeFavorite(listingId: listing.id)
        favoritedListings.removeAll { $0.id == listing.id }
    }

    func distance(to listing: Listing) -> CLLocationDistance? {
        locationService.distance(to: listing.location.coordinate)
    }

    func formattedDistance(to listing: Listing) -> String {
        Formatters.formattedDistance(distance(to: listing))
    }
}
