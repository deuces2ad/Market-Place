//
//  FavoritesView.swift
//  Market Place
//

import SwiftUI
import Models
import Core

struct FavoritesView<ViewModel: FavoritesViewModelProtocol>: View {

    @ObservedObject
    var viewModel: ViewModel
    @EnvironmentObject
    private var factory: ViewModelFactory

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.favoritedListings.isEmpty {
                    emptyView
                } else {
                    favoriteList
                }
            }
            .navigationTitle("Favorites")
            .onAppear {
                viewModel.loadFavorites()
            }
        }
    }

    private var favoriteList: some View {
        List {
            ForEach(viewModel.favoritedListings) { listing in
                NavigationLink(value: listing) {
                    ListingRowView(
                        listing: listing,
                        distance: viewModel.formattedDistance(to: listing),
                        onFavoriteTapped: {
                            viewModel.removeFavorite(for: listing)
                        }
                    )
                }
            }
            .onDelete { offsets in
                let listingsToRemove = offsets.map { viewModel.favoritedListings[$0] }
                for listing in listingsToRemove {
                    viewModel.removeFavorite(for: listing)
                }
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: Listing.self) { listing in
            ListingDetailView(
                viewModel: ListingDetailViewModel(
                    listing: listing,
                    listingRepository: factory.container.listingRepository,
                    locationService: factory.container.locationService,
                    syncEngine: factory.container.syncEngine
                )
            )
        }
    }

    private var emptyView: some View {
        ContentUnavailableView(
            "No Favorites Yet",
            systemImage: "heart",
            description: Text("Listings you favorite will appear here.")
        )
    }
}
