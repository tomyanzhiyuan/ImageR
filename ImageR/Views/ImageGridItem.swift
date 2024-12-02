//
//  ImageGridItem.swift
//  ImageR
//
//  Created by Tom Yan Zhiyuan on 01/12/2024.
//

import SwiftUI
import PhotosUI

struct ImageGridItem: View {
    let image: GeneratedImage
    let onDelete: () -> Void
    let onSave: () -> Void
    @State private var showingOptions = false
    @State private var showingSaveSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        AsyncImage(url: image.url) { phase in
            switch phase {
            case .success(let loadedImage):
                loadedImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 150)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(alignment: .topTrailing) {
                        Button {
                            showingOptions = true
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(4)
                    }
                    .confirmationDialog("Image Options", isPresented: $showingOptions) {
                        Button("Save to Photos") {
                            Task {
                                do {
                                    try await PhotoManager.saveToAlbum(url: image.url)
                                    showingSaveSuccess = true
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showingError = true
                                }
                            }
                        }
                        Button("Delete", role: .destructive) { onDelete() }
                        Button("Cancel", role: .cancel) { }
                    }
            case .failure(_):
                Image(systemName: "xmark.circle")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
                    .frame(width: 150, height: 150)
            case .empty:
                ProgressView()
                    .frame(width: 150, height: 150)
            @unknown default:
                EmptyView()
            }
        }
        .alert("Saved!", isPresented: $showingSaveSuccess) {
            Button("OK", role: .cancel) { }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

struct ImageGridView: View {
    @ObservedObject var storageManager: ImageStorageManager
    @Binding var selectedImage: GeneratedImage?
    @Binding var showingDetail: Bool
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
            ForEach(storageManager.savedImages.reversed()) { image in
                ImageGridItem(image: image) {
                    // Delete action
                    storageManager.deleteImage(image)
                } onSave: {
                    // Save action
                    Task {
                        do {
                            try await PhotoManager.saveToAlbum(url: image.url)
                            // Show success alert
                        } catch {
                            // Show error alert
                        }
                    }
                }
                .onTapGesture {
                    selectedImage = image
                    showingDetail = true
                }
            }
        }
        .padding()
    }
}

//#Preview {
//    ImageGridItem()
//}
