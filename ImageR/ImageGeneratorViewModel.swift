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
    
    @Published var isLoading = false
    @Published var error: String?
    
    init(apiToken: String) {
        self.replicateService = ReplicateService(apiToken: apiToken)
    }
    
    func generateImage(prompt: String, aspectRatio: ImageAspectRatio = .square) async -> URL? {
        isLoading = true
        error = nil
        
        do {
            let imageURL = try await replicateService.runImageGeneration(prompt: prompt, aspectRatio: aspectRatio)
            isLoading = false
            return imageURL
        } catch {
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
