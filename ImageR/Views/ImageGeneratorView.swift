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
    @State private var prompt: String = ""
    @State private var imageURL: String = ""
    @State private var selectedTab = 0
    
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
                            await viewModel.generateImage(prompt: prompt)
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
                                await viewModel.restoreImage(url: url)
                            }
                        }
                    }
                    .disabled(imageURL.isEmpty || viewModel.isLoading)
                }
                
                if viewModel.isLoading {
                    ProgressView()
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
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(height: 150)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("AI Image Generator")
        }
    }
}
