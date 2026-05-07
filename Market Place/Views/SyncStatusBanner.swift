//
//  SyncStatusBanner.swift
//  Market Place
//

import SwiftUI
import Combine
import Core

struct SyncStatusBanner: View {

    let status: SyncEngineStatus
    var onRetry: (() -> Void)?

    var body: some View {
        if status.hasPendingWork || status.isSyncing || status.lastError != nil {
            HStack(spacing: 10) {
                if status.isSyncing {
                    ProgressView()
                        .controlSize(.small)
                    Text("Syncing...")
                        .font(.caption.weight(.medium))
                } else if let error = status.lastError {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                    Spacer()
                    if let onRetry {
                        Button("Retry", action: onRetry)
                            .font(.caption.weight(.semibold))
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                    }
                } else if !status.isOnline {
                    Image(systemName: "wifi.slash")
                        .foregroundStyle(.orange)
                    Text("Offline — \(status.pendingUploads + status.pendingEdits) pending")
                        .font(.caption)
                } else {
                    Image(systemName: "icloud.and.arrow.up")
                        .foregroundStyle(.blue)
                    Text("\(status.pendingUploads) uploads, \(status.pendingEdits) edits pending")
                        .font(.caption)
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
    }
}
