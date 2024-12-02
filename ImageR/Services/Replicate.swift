//
//  Replicate.swift
//  ImageR
//
//  Created by Tom Yan Zhiyuan on 01/12/2024.
//

import Foundation
import Replicate

enum ImageAspectRatio: String {
    case landscape = "16:9"
    case portrait = "9:16"
    case square = "1:1"
}

class ReplicateService {
    private let client: Replicate.Client
    
    init(apiToken: String) {
        self.client = Replicate.Client(token: apiToken)
    }
    
    func runImageGeneration(prompt: String, aspectRatio: ImageAspectRatio = .square) async throws -> URL? {
            let model = try await client.getModel("stability-ai/stable-diffusion-3")
            
            if let latestVersion = model.latestVersion {
                let input: [String: Replicate.Value] = [
                    "prompt": .string(prompt),
                    "aspect_ratio": .string(aspectRatio.rawValue)
                ]
                
                let prediction = try await client.createPrediction(
                    version: latestVersion.id,
                    input: input
                )
                
                // Poll for completion
                var currentPrediction = prediction
                repeat {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1 second
                    currentPrediction = try await client.getPrediction(id: prediction.id)
                } while currentPrediction.status.rawValue == "starting" ||
                       currentPrediction.status.rawValue == "processing"
                
                if let output = currentPrediction.output,
                   case let .array(values) = output,
                   let firstOutput = values.first,
                   case let .string(urlString) = firstOutput,
                   let outputURL = URL(string: urlString) {
                    return outputURL
                }
            }
            return nil
        }
    
    func runFaceRestoration(imageData: Data) async throws -> URL? {
        let model = try await client.getModel("tencentarc/gfpgan")
        
        if let latestVersion = model.latestVersion {
            // Convert image data to base64
            let base64String = "data:image/jpeg;base64," + imageData.base64EncodedString()
            
            let input: [String: Replicate.Value] = [
                "img": .string(base64String)
            ]
            
            let prediction = try await client.createPrediction(
                version: latestVersion.id,
                input: input
            )
            
            // Poll for completion
            var currentPrediction = prediction
            repeat {
                try await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1 second
                currentPrediction = try await client.getPrediction(id: prediction.id)
            } while currentPrediction.status.rawValue == "starting" ||
            currentPrediction.status.rawValue == "processing"
            
            if let output = currentPrediction.output,
               case let .array(values) = output,
               let firstOutput = values.first,
               case let .string(urlString) = firstOutput,
               let outputURL = URL(string: urlString) {
                return outputURL
            }
        }
        return nil
    }
}
