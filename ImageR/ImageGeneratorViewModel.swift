//
//  ImageGeneratorViewModel.swift
//  ImageR
//
//  Created by Tom Yan Zhiyuan on 01/12/2024.
//

import Foundation
import SwiftUI

@MainActor
class ImageGeneratorViewModel: ObservableObject {
    private let replicateService: ReplicateService
    
    @Published var generatedImages: [URL] = []
    @Published var isLoading = false
    @Published var error: String?
    
    init(apiToken: String) {
        self.replicateService = ReplicateService(apiToken: apiToken)
    }
    
    func generateDisposableImage(prompt: String) async {
        isLoading = true
        error = nil
        
        do {
            // Start the prediction
            let prediction = try await replicateService.runDisposableCamera(prompt: prompt)
            
            // Poll for results
            var currentPrediction = prediction
            while currentPrediction.status != "succeeded" && currentPrediction.status != "failed" {
                try await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1 second
                currentPrediction = try await replicateService.checkPrediction(id: prediction.id)
            }
            
            if let outputs = currentPrediction.output {
                generatedImages = outputs.compactMap { URL(string: $0) }
            } else if let error = currentPrediction.error {
                self.error = error
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func restoreImage(url: String) async {
        isLoading = true
        error = nil
        
        do {
            let prediction = try await replicateService.runFaceRestoration(imageURL: url)
            
            var currentPrediction = prediction
            while currentPrediction.status != "succeeded" && currentPrediction.status != "failed" {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                currentPrediction = try await replicateService.checkPrediction(id: prediction.id)
            }
            
            if let outputs = currentPrediction.output {
                generatedImages = outputs.compactMap { URL(string: $0) }
            } else if let error = currentPrediction.error {
                self.error = error
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
}
