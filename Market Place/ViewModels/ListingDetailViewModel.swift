//
//  ListingDetailViewModel.swift
//  Market Place
//

import Foundation
import Combine
import CoreLocation
import MapKit
import Models
import Core

protocol ListingDetailViewModelProtocol: ObservableObject {
    var listing: Listing { get set }
    var distance: CLLocationDistance? { get }
    var formattedDistance: String { get }

    func toggleFavorite()
    func openInMaps()
}

@MainActor
final class ListingDetailViewModel: ListingDetailViewModelProtocol {
    @Published
    var listing: Listing

    private let listingRepository: ListingRepository
    private let locationService: LocationServiceProtocol
    private let syncEngine: SyncEngineProtocol

    init(
        listing: Listing,
        listingRepository: ListingRepository,
        locationService: LocationServiceProtocol,
        syncEngine: SyncEngineProtocol
    ) {
        self.listing = listing
        self.listingRepository = listingRepository
        self.locationService = locationService
        self.syncEngine = syncEngine
    }

    func toggleFavorite() {
        let newState = !listing.isFavorited
        if newState {
            _ = listingRepository.addFavorite(listingId: listing.id)
        } else {
            _ = listingRepository.removeFavorite(listingId: listing.id)
        }
        listing.isFavorited = newState
    }

    var distance: CLLocationDistance? {
        locationService.distance(to: listing.location.coordinate)
    }

    var formattedDistance: String {
        Formatters.formattedDistance(distance)
    }

    func openInMaps() {
        let coordinate = listing.location.coordinate
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = listing.title
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault
        ])
    }
}
