//
//  ContentView.swift
//  Market Place
//
//  Created by Vijay Kumar on 07/05/26.
//

import SwiftUI
import Combine
import Models
import Networking
import Core

struct ContentView: View {

    @EnvironmentObject private var container: DependencyContainer
    @EnvironmentObject private var factory: ViewModelFactory
    @State private var syncStatus = SyncEngineStatus.initial

    @State private var listingsVM: ListingsViewModel?
    @State private var favoritesVM: FavoritesViewModel?
    @State private var createListingVM: CreateListingViewModel?

    var body: some View {
        VStack(spacing: 0) {
            SyncStatusBanner(status: syncStatus) {
                Task { await container.syncEngine.retryFailed() }
            }

            if let listingsVM, let favoritesVM, let createListingVM {
                TabView {
                    ListingsView(viewModel: listingsVM)
                        .tabItem {
                            Label("Browse", systemImage: "magnifyingglass")
                        }

                    FavoritesView(viewModel: favoritesVM)
                        .tabItem {
                            Label("Favorites", systemImage: "heart")
                        }

                    CreateListingView(viewModel: createListingVM)
                        .tabItem {
                            Label("Sell", systemImage: "plus.circle")
                        }
                }
                .tint(.green)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            container.locationService.requestPermission()
            if listingsVM == nil {
                listingsVM = ListingsViewModel(
                    listingRepository: container.listingRepository,
                    locationService: container.locationService
                )
            }
            if favoritesVM == nil {
                favoritesVM = FavoritesViewModel(
                    listingRepository: container.listingRepository,
                    locationService: container.locationService
                )
            }
            if createListingVM == nil {
                createListingVM = CreateListingViewModel(
                    listingRepository: container.listingRepository,
                    locationService: container.locationService,
                    syncEngine: container.syncEngine
                )
            }
        }
        .onReceive(container.syncEngine.syncStatusPublisher) { newStatus in
            if newStatus != syncStatus {
                syncStatus = newStatus
            }
        }
    }
}

#Preview {
    let container = DependencyContainer()
    ContentView()
        .environmentObject(container)
        .environmentObject(ViewModelFactory(container: container))
}
