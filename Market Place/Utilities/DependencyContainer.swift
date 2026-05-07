//
//  DependencyContainer.swift
//  Market Place
//

import Foundation
import Combine
import Models
import Networking
import Core

final class DependencyContainer: ObservableObject {
    let locationService: LocationService
    let listingRepository: ListingRepository
    let syncEngine: SyncEngineProtocol

    init() {
        let remoteDataSource = RemoteDataSource()
        self.locationService = LocationService()
        let repository = ListingRepositoryImplementation(
            remoteDataSource: remoteDataSource)
        self.listingRepository = repository
        self.syncEngine = SyncEngine(
            remoteDataSource: remoteDataSource,
            listingRepository: repository)
    }
}

// MARK: - ViewModel Factory

final class ViewModelFactory: ObservableObject {

    let container: DependencyContainer

    init(container: DependencyContainer) {
        self.container = container
    }

    func createListingsViewModel() -> some ListingsViewModelProtocol {
        return ListingsViewModel(
            listingRepository: container.listingRepository,
            locationService: container.locationService
        )
    }

    func createListingDetailViewModel(listing: Listing) -> some ListingDetailViewModelProtocol {
        return ListingDetailViewModel(
            listing: listing,
            listingRepository: container.listingRepository,
            locationService: container.locationService,
            syncEngine: container.syncEngine
        )
    }

    func createFavoritesViewModel() -> some FavoritesViewModelProtocol {
        return FavoritesViewModel(
            listingRepository: container.listingRepository,
            locationService: container.locationService
        )
    }

    func createCreateListingViewModel() -> some CreateListingViewModelProtocol {
        return CreateListingViewModel(
            listingRepository: container.listingRepository,
            locationService: container.locationService,
            syncEngine: container.syncEngine
        )
    }
}
