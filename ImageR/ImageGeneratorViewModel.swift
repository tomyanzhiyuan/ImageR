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
    
    func generateImage(prompt: String) async -> URL? {
        isLoading = true
        error = nil
        
        do {
            if let imageURL = try await replicateService.runImageGeneration(prompt: prompt) {
                return imageURL
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
        return nil
    }
    
    func restoreImage(url: URL) async -> URL? {
        isLoading = true
        error = nil
        
        do {
            if let restoredURL = try await replicateService.runFaceRestoration(imageURL: url) {
                return restoredURL
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
        return nil
    }
}
