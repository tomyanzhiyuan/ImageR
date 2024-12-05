//
//  ImageGridItem.swift
//  ImageR
//
//  Created by Tom Yan Zhiyuan on 01/12/2024.
//

import SwiftUI
import PhotosUI

struct ImageGridView: View {
    @ObservedObject var storageManager: ImageStorageManager
    @Binding var selectedImage: GeneratedImage?
    @Binding var showingDetail: Bool
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
            if storageManager.savedImages.isEmpty {
                Text("No images yet")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            } else {
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
        }
        .padding()
    }
}

struct ImageGridItem: View {
    let image: GeneratedImage
    let onDelete: () -> Void
    
    @State private var showingOptions = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSaveSuccess = false
    @State private var isSaving = false
    @State private var isDeleting = false  // New state for deletion animation
    
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
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 30))
                            .foregroundColor(.red)
                        Text("Failed to load")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .frame(width: 150, height: 150)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                @unknown default:
                    EmptyView()
                }
            }
        }
        .frame(width: 150, height: 150)
        .scaleEffect(isDeleting ? 0.1 : 1.0)  // Scale down when deleting
        .opacity(isDeleting ? 0 : 1)          // Fade out when deleting
        .animation(.easeInOut(duration: 0.3), value: isDeleting)  // Animate changes
        .confirmationDialog("Image Options", isPresented: $showingOptions) {
            Button("Save to Photos") {
                saveImage()
            }
            Button("Delete", role: .destructive) {
                withAnimation {
                    isDeleting = true
                }
                // Delay the actual deletion to allow animation to complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDelete()
                }
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
