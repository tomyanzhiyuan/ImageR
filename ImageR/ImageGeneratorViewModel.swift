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
    private let settingsManager: SettingsManager
    
    @Published var isLoading = false
    @Published var error: String?
    
    init(apiToken: String, settingsManager: SettingsManager) {
        print("Initializing ViewModel with API token: \(apiToken.prefix(5))...")
        self.replicateService = ReplicateService(apiToken: apiToken)
        self.settingsManager = settingsManager
    }
    
    func generateImages(prompt: String, aspectRatio: ImageAspectRatio = .square) async -> [(URL, ImageMetadata)]? {
        print("Starting image generation in ViewModel")
        isLoading = true
        error = nil
        
        var results: [(URL, ImageMetadata)] = []
        
        do {
            for _ in 0..<settingsManager.imagesPerGeneration {
                if let result = try await replicateService.runImageGeneration(prompt: prompt, aspectRatio: aspectRatio) {
                    results.append((result.url, result.metadata))
                }
            }
            
            isLoading = false
            return results.isEmpty ? nil : results
            
        } catch {
            print("Generation failed with error: \(error)")
            self.error = error.localizedDescription
            isLoading = false
            return nil
        }
    }
    
    func restoreImage(imageData: Data) async -> URL? {
        isLoading = true
        error = nil
        print("Starting face restoration...")
        
        do {
            guard let url = try await replicateService.runFaceRestoration(imageData: imageData) else {
                print("No URL returned from face restoration")
                self.error = "Failed to restore face - no result returned"
                isLoading = false
                return nil
            }
            
            print("Face restoration successful, URL: \(url)")
            isLoading = false
            return url
            
        } catch {
            print("Face restoration failed with error: \(error)")
            self.error = "Failed to restore face: \(error.localizedDescription)"
            isLoading = false
            return nil
        }
    }
}
