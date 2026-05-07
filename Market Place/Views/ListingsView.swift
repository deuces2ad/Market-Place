//
//  ListingsView.swift
//  Market Place
//

import SwiftUI
import Models
import Core

struct ListingsView<ViewModel: ListingsViewModelProtocol>: View {

    @ObservedObject var viewModel: ViewModel
    @EnvironmentObject private var factory: ViewModelFactory

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.listings.isEmpty {
                    loadingView
                } else if let error = viewModel.errorMessage, viewModel.listings.isEmpty {
                    errorView(error)
                } else {
                    listingList
                }
            }
            .navigationTitle("Marketplace")
            .searchable(text: $viewModel.searchText, prompt: "Search listings")
            .refreshable {
                await viewModel.refresh()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    categoryMenu
                }
            }
            .task {
                if viewModel.listings.isEmpty {
                    await viewModel.loadListings(forceRefresh: false)
                }
            }
        }
    }

    // MARK: - Listing List

    private var listingList: some View {
        List {
            ForEach(viewModel.filteredListings) { listing in
                NavigationLink(value: listing) {
                    ListingRowView(
                        listing: listing,
                        distance: viewModel.formattedDistance(to: listing),
                        onFavoriteTapped: {
                            viewModel.toggleFavorite(for: listing)
                        }
                    )
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
        .overlay {
            if viewModel.filteredListings.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
            }
        }
    }

    // MARK: - Category Filter

    private var categoryMenu: some View {
        Menu {
            Button("All Categories") {
                viewModel.selectedCategory = nil
            }
            Divider()
            ForEach(ListingCategory.allCases, id: \.self) { category in
                Button {
                    viewModel.selectedCategory = category
                } label: {
                    Label(category.rawValue, systemImage: category.systemImage)
                }
            }
        } label: {
            Image(systemName: viewModel.selectedCategory != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Finding listings near you...")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Unable to Load Listings", systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                Task { await viewModel.loadListings(forceRefresh: true) }
            }
            .buttonStyle(.bordered)
        }
    }
}
