//
//  ListingDetailView.swift
//  Market Place
//

import SwiftUI
import MapKit
import Models
import Core

struct ListingDetailView<ViewModel: ListingDetailViewModelProtocol>: View {

    @ObservedObject var viewModel: ViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heroImage
                detailContent
            }
        }
        .ignoresSafeArea(.container, edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                favoriteButton
            }
        }
    }

    private var heroImage: some View {
        CachedAsyncImage(urlString: viewModel.listing.imageUrls.first ?? "")
            .frame(height: 280)
            .clipped()
            .overlay(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [.clear, .black.opacity(0.6)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    categoryBadge
                    Text(viewModel.listing.title)
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    Text(Formatters.formattedPrice(viewModel.listing.price))
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.green)
                }
                .padding()
            }
    }

    // MARK: - Detail Content

    private var detailContent: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Quick info row
            HStack(spacing: 20) {
                infoChip(icon: "clock", text: Formatters.relativeTime(from: viewModel.listing.postedDate))
                infoChip(icon: "location", text: viewModel.formattedDistance)
                infoChip(icon: "person", text: viewModel.listing.sellerName)
            }

            // Sync status
            if viewModel.listing.syncStatus != .synced {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.listing.syncStatus.systemImage)
                    Text(viewModel.listing.syncStatus.rawValue)
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.orange)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.orange.opacity(0.1), in: Capsule())
            }

            Divider()

            // Date Posted
            VStack(alignment: .leading, spacing: 6) {
                Text("Posted")
                    .font(.headline)
                Text(Formatters.fullDate(viewModel.listing.postedDate))
                    .foregroundStyle(.secondary)
            }

            // Address & Map
            VStack(alignment: .leading, spacing: 6) {
                Text("Location")
                    .font(.headline)
                Text(viewModel.listing.location.address)
                    .foregroundStyle(.secondary)

                Map(initialPosition: .region(MKCoordinateRegion(
                    center: viewModel.listing.location.coordinate,
                    latitudinalMeters: 1000,
                    longitudinalMeters: 1000
                )), interactionModes: []) {
                    Marker(viewModel.listing.title, coordinate: viewModel.listing.location.coordinate)
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    viewModel.openInMaps()
                } label: {
                    Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }

            Divider()

            // Description
            VStack(alignment: .leading, spacing: 6) {
                Text("Description")
                    .font(.headline)
                Text(viewModel.listing.description)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
    }

    // MARK: - Components

    private var categoryBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: viewModel.listing.category.systemImage)
            Text(viewModel.listing.category.rawValue)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private func infoChip(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(.green)
            Text(text)
                .font(.subheadline.weight(.medium))
        }
    }

    private var favoriteButton: some View {
        Button {
            viewModel.toggleFavorite()
        } label: {
            Image(systemName: viewModel.listing.isFavorited ? "heart.fill" : "heart")
                .foregroundStyle(viewModel.listing.isFavorited ? .red : .primary)
        }
    }
}
