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
    private let faceRestorationModelVersion = "9283608cc6b7be6b65a8e44983db012355fde4132009bf99d976b2f0896856a3"
    
    init(apiToken: String) {
        self.client = Replicate.Client(token: apiToken)
    }
    
    func runImageGeneration(prompt: String, aspectRatio: ImageAspectRatio = .square) async throws -> URL? {
        let model = try await client.getModel("stability-ai/stable-diffusion-3")
        
        if let latestVersion = model.latestVersion {
            // Get quality settings from UserDefaults
                        let defaults = UserDefaults.standard
            let qualitySettings = defaults.dictionary(forKey: "replicateSettings") ?? [:]
            
            var input: [String: Replicate.Value] = [
                "prompt": .string(prompt),
                "aspect_ratio": .string(aspectRatio.rawValue)
            ]
            
            // Add quality settings
            if let steps = qualitySettings["num_inference_steps"] as? Int {
                input["num_inference_steps"] = .int(steps)
            }
            if let guidance = qualitySettings["guidance_scale"] as? Double {
                input["guidance_scale"] = .double(guidance)
            }
            
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
        print("Starting face restoration process...")
        
        // Convert input to base64 and create a data URI
        let base64String = imageData.base64EncodedString()
        let dataURI = "data:image/jpeg;base64,\(base64String)"
        
        // Create prediction with the proper input format
        let input: [String: Replicate.Value] = [
            "img": .string(dataURI),  // Changed from 'image' to 'img'
            "version": .string("v1.4"),
            "scale": .int(2)  // Optional: Add scale parameter for better quality
        ]
        
        print("Creating prediction for face restoration...")
        
        let prediction = try await client.createPrediction(
            version: faceRestorationModelVersion,
            input: input
        )
        
        // Poll for completion with improved error handling
        var currentPrediction = prediction
        var attempts = 0
        let maxAttempts = 30  // 60 seconds total with 2-second intervals
        
        repeat {
            try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 second intervals
            currentPrediction = try await client.getPrediction(id: prediction.id)
            print("Prediction status: \(currentPrediction.status.rawValue)")
            
            if let error = currentPrediction.error {
                throw NSError(
                    domain: "ReplicateService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Face restoration failed: \(error)"]
                )
            }
            
            attempts += 1
            if attempts >= maxAttempts {
                throw NSError(
                    domain: "ReplicateService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Face restoration timed out"]
                )
            }
            
        } while currentPrediction.status.rawValue == "starting" ||
                currentPrediction.status.rawValue == "processing"
        
        // Handle the output based on its structure
        if let output = currentPrediction.output {
            print("Received output: \(output)")
            
            switch output {
            case .string(let urlString):
                return URL(string: urlString)
                
            case .array(let values):
                if let firstValue = values.first,
                   case let .string(urlString) = firstValue {
                    return URL(string: urlString)
                }
                
            case .object(let dict):
                if let outputValue = dict["output"],
                   case let .string(urlString) = outputValue {
                    return URL(string: urlString)
                }
                
            default:
                throw NSError(
                    domain: "ReplicateService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Unexpected output format"]
                )
            }
        }
        
        throw NSError(
            domain: "ReplicateService",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "No output URL in response"]
        )
    }
}
