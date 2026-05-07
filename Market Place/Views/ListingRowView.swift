//
//  ListingRowView.swift
//  Market Place
//

import SwiftUI
import Models
import Core

struct ListingRowView: View {

    let listing: Listing
    let distance: String
    let onFavoriteTapped: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail
            CachedAsyncImage(
                urlString: listing.imageUrls.first ?? "",
                thumbnailSize: CGSize(width: 80, height: 80)
            )
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(Formatters.formattedPrice(listing.price))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)

                HStack(spacing: 4) {
                    Image(systemName: listing.category.systemImage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(listing.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Label(Formatters.relativeTime(from: listing.postedDate), systemImage: "clock")
                    Label(distance, systemImage: "location")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                // Sync status indicator
                if listing.syncStatus != .synced {
                    HStack(spacing: 4) {
                        Image(systemName: listing.syncStatus.systemImage)
                        Text(listing.syncStatus.rawValue)
                    }
                    .font(.caption2)
                    .foregroundStyle(.orange)
                }
            }

            Spacer()

            // Favorite button
            Button(action: onFavoriteTapped) {
                Image(systemName: listing.isFavorited ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundStyle(listing.isFavorited ? .red : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
