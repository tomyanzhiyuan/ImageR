//
//  ImageGeneratorView.swift
//  ImageR
//
//  Created by Tom Yan Zhiyuan on 01/12/2024.
//
import Foundation
import SwiftUI
import PhotosUI

struct ImageGeneratorView: View {
    @ObservedObject var viewModel: ImageGeneratorViewModel
    @StateObject private var storageManager = ImageStorageManager()
    @EnvironmentObject private var settingsManager: SettingsManager

    @State private var prompt: String = ""
    @State private var selectedTab = 0
    @State private var selectedImage: GeneratedImage? = nil
    @State private var showingDetail = false
    @State private var selectedAspectRatio: ImageAspectRatio = .square
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var showingLoadingPhoto = false
    @State private var showingRestorationSuccess = false
    @State private var showingRestorationError = false
    @State private var restorationError = ""
    
    var body: some View {
        NavigationView {
            VStack {
                modePicker
                
                if selectedTab == 0 {
                    imageGenerationContent
                } else {
                    faceRestorationContent
                }
                
                if viewModel.isLoading || showingLoadingPhoto {
                    ProgressView()
                        .padding()
                }
                
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                imageGrid
            }
            .sheet(isPresented: $showingDetail) {
                imageDetailSheet
            }
            .onChange(of: selectedItem) { _, newItem in
                handleSelectedItemChange(newItem)
            }
            .alert("Restoration Complete!", isPresented: $showingRestorationSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your restored image has been added to the gallery below")
            }
            .alert("Restoration Failed", isPresented: $showingRestorationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(restorationError)
            }
        }
    }
    
    // MARK: - View Components
    
    private var modePicker: some View {
        Picker("Mode", selection: $selectedTab) {
            Text("Generate Image").tag(0)
            Text("Restore Face").tag(1)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }
    
    private var imageGenerationContent: some View {
        VStack {
            Picker("Aspect Ratio", selection: $selectedAspectRatio) {
                Text("Square").tag(ImageAspectRatio.square)
                Text("Landscape").tag(ImageAspectRatio.landscape)
                Text("Portrait").tag(ImageAspectRatio.portrait)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            TextField("Enter prompt for image generation", text: $prompt)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            generateButton
        }
    }
    
    private var generateButton: some View {
        Button("Generate") {
            Task {
                if let results = await viewModel.generateImages(prompt: prompt, aspectRatio: selectedAspectRatio) {
                    for (url, metadata) in results {
                        let generatedImage = await GeneratedImage(
                            url: url,
                            prompt: prompt,
                            type: .generated,
                            metadata: metadata
                        )
                        storageManager.saveImage(generatedImage)
                        
                        if settingsManager.autoSaveToPhotos {
                            try? await PhotoManager.saveToAlbum(url: url)
                        }
                    }
                }
            }
        }
        .disabled(prompt.isEmpty || viewModel.isLoading)
    }
    
    private var faceRestorationContent: some View {
        VStack(spacing: 20) {
            if let selectedImageData,
               let uiImage = UIImage(data: selectedImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(8)
            }
            
            photoPickerButton
            
            if selectedImageData != nil {
                restoreButton
            }
        }
    }
    
    private var photoPickerButton: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            Label("Select Photo", systemImage: "photo.fill")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
                .padding(.horizontal)
        }
    }
    
    private var restoreButton: some View {
        Button("Restore Face") {
            Task {
                if let url = await viewModel.restoreImage(imageData: selectedImageData!) {
                    let restoredImage = await GeneratedImage(
                        url: url,
                        type: .restored
                    )
                    storageManager.saveImage(restoredImage)
                    showingRestorationSuccess = true
                    selectedImageData = nil
                } else if let error = viewModel.error {
                    restorationError = error
                    showingRestorationError = true
                }
            }
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.green)
        .cornerRadius(10)
        .padding(.horizontal)
        .disabled(viewModel.isLoading)
    }
    
    private var imageGrid: some View {
        ScrollView {
            ImageGridView(
                storageManager: storageManager,
                selectedImage: $selectedImage,
                showingDetail: $showingDetail
            )
        }
    }
    
    private var imageDetailSheet: some View {
        Group {
            if let image = selectedImage {
                ImageDetailView(image: image)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleSelectedItemChange(_ newItem: PhotosPickerItem?) {
        Task {
            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                selectedImageData = data
            }
        }
    }
}
