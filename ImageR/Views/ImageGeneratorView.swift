//
//  ImageGeneratorView.swift
//  ImageR
//
//  Created by Tom Yan Zhiyuan on 01/12/2024.
//
import Foundation
import SwiftUI

struct ImageGeneratorView: View {
    @ObservedObject var viewModel: ImageGeneratorViewModel
    @StateObject private var storageManager = ImageStorageManager()
    @State private var prompt: String = ""
    @State private var imageURL: String = ""
    @State private var selectedTab = 0
    @State private var selectedImage: GeneratedImage? = nil
    @State private var showingDetail = false
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Mode", selection: $selectedTab) {
                    Text("Generate Image").tag(0)
                    Text("Restore Face").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    TextField("Enter prompt for image generation", text: $prompt)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Button("Generate") {
                        Task {
                            if let url = await viewModel.generateImage(prompt: prompt) {
                                let generatedImage = GeneratedImage(
                                    url: url,
                                    prompt: prompt,
                                    type: .generated
                                )
                                storageManager.saveImage(generatedImage)
                            }
                        }
                    }
                    .disabled(prompt.isEmpty || viewModel.isLoading)
                } else {
                    TextField("Enter image URL for restoration", text: $imageURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Button("Restore") {
                        if let url = URL(string: imageURL) {
                            Task {
                                if let restoredUrl = await viewModel.restoreImage(url: url) {
                                    let restoredImage = GeneratedImage(
                                        url: restoredUrl,
                                        type: .restored
                                    )
                                    storageManager.saveImage(restoredImage)
                                }
                            }
                        }
                    }
                    .disabled(imageURL.isEmpty || viewModel.isLoading)
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }
                
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                        ForEach(storageManager.savedImages.reversed()) { image in
                            AsyncImage(url: image.url) { phase in
                                switch phase {
                                case .success(let loadedImage):
                                    loadedImage
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 150, height: 150)
                                        .clipped()
                                        .cornerRadius(8)
                                        .onTapGesture {
                                            selectedImage = image
                                            showingDetail = true
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
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("AI Image Generator")
            .sheet(isPresented: $showingDetail) {
                if let image = selectedImage {
                    ImageDetailView(image: image)
                }
            }
        }
    }
}
