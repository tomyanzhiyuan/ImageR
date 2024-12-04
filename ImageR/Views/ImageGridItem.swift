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
    
    @State private var showingOptions = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSaveSuccess = false
    @State private var isSaving = false
    @State private var imageLoadError = false
    
    var body: some View {
        Group {
            AsyncImage(url: image.url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 150, height: 150)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 150)
                        .clipped()
                        .cornerRadius(8)
                        .overlay(alignment: .topTrailing) {
                            optionsButton
                        }
                case .failure:
                    errorView
                @unknown default:
                    errorView
                }
            }
        }
        .frame(width: 150, height: 150)
        .confirmationDialog("Image Options", isPresented: $showingOptions) {
            Button("Save to Photos") {
                saveImage()
            }
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showingSaveSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Image saved successfully to Photos")
        }
    }
    
    private var optionsButton: some View {
        Button {
            showingOptions = true
        } label: {
            if isSaving {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            } else {
                Image(systemName: "ellipsis")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
        }
        .padding(4)
        .disabled(isSaving)
    }
    
    private var errorView: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 30))
                .foregroundColor(.red)
            Text("Failed to load image")
                .font(.caption)
                .foregroundColor(.red)
        }
        .frame(width: 150, height: 150)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func saveImage() {
        Task {
            isSaving = true
            do {
                try await PhotoManager.saveToAlbum(url: image.url)
                showingSaveSuccess = true
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            isSaving = false
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
                    storageManager.deleteImage(image)
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
