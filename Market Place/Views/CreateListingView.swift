//
//  CreateListingView.swift
//  Market Place
//

import SwiftUI
import PhotosUI
import Models
import Core

struct CreateListingView<ViewModel: CreateListingViewModelProtocol>: View {

    @ObservedObject var viewModel: ViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Photos Section
                Section("Photos") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.selectedImages.indices, id: \.self) { index in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: viewModel.selectedImages[index])
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))

                                    Button {
                                        viewModel.removeImage(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.white, .red)
                                    }
                                    .offset(x: 6, y: -6)
                                }
                            }

                            if viewModel.selectedImages.count < 5 {
                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(.systemGray5))
                                        .frame(width: 100, height: 100)
                                        .overlay {
                                            VStack(spacing: 4) {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.title2)
                                                Text("Add")
                                                    .font(.caption)
                                            }
                                            .foregroundStyle(.secondary)
                                        }
                                }
                                .onChange(of: selectedPhotoItem) { _, newItem in
                                    Task {
                                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                                           let image = UIImage(data: data) {
                                            viewModel.addImage(image)
                                        }
                                        selectedPhotoItem = nil
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Details Section
                Section("Details") {
                    TextField("Title", text: $viewModel.title)
                    TextField("Description", text: $viewModel.description, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Price", text: $viewModel.priceText)
                        .keyboardType(.decimalPad)
                }

                // Category Section
                Section("Category") {
                    Picker("Category", selection: $viewModel.selectedCategory) {
                        ForEach(ListingCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.systemImage)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                // Post Button
                Section {
                    Button {
                        viewModel.saveListing()
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isSaving {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text(viewModel.isSaving ? "Saving..." : "Post Listing")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                }

                if let error = viewModel.saveError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Listing")
            .alert("Listing Saved", isPresented: $viewModel.didSave) {
                Button("OK") {
                    viewModel.reset()
                }
            } message: {
                Text("Your listing has been queued and will sync when online.")
            }
        }
    }
}



