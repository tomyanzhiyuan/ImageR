//
//  ImageGeneratorView.swift
//  ImageR
//
//  Created by Tom Yan Zhiyuan on 01/12/2024.
//

import Foundation
import SwiftUI

struct ImageGeneratorView: View {
    @StateObject private var viewModel: ImageGeneratorViewModel
    @State private var prompt: String = ""
    @State private var imageURL: String = ""
    @State private var selectedTab = 0
    
    init(apiToken: String) {
        _viewModel = StateObject(wrappedValue: ImageGeneratorViewModel(apiToken: apiToken))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Mode", selection: $selectedTab) {
                    Text("Disposable Camera").tag(0)
                    Text("Face Restoration").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    disposableCameraView
                } else {
                    faceRestorationView
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .padding()
                }
                
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                        ForEach(viewModel.generatedImages, id: \.self) { imageUrl in
                            AsyncImage(url: imageUrl) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(8)
                            } placeholder: {
                                ProgressView()
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("AI Image Generator")
        }
    }
    
    private var disposableCameraView: some View {
        VStack {
            TextField("Enter prompt for image generation", text: $prompt)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Generate Image") {
                Task {
                    await viewModel.generateDisposableImage(prompt: prompt)
                }
            }
            .disabled(prompt.isEmpty || viewModel.isLoading)
        }
    }
    
    private var faceRestorationView: some View {
        VStack {
            TextField("Enter image URL for restoration", text: $imageURL)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Restore Image") {
                Task {
                    await viewModel.restoreImage(url: imageURL)
                }
            }
            .disabled(imageURL.isEmpty || viewModel.isLoading)
        }
    }
}
