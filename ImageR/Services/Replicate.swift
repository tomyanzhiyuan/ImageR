//
//  Replicate.swift
//  ImageR
//
//  Created by Tom Yan Zhiyuan on 01/12/2024.
//

import Foundation
import Replicate

struct ImageGenerationResult {
    let url: URL
    let metadata: ImageMetadata
}

public struct ImageMetadata: Codable, Equatable {
    public let inferenceSteps: Int
    public let guidanceScale: Double
    public let aspectRatio: String
    
    public init(inferenceSteps: Int, guidanceScale: Double, aspectRatio: String) {
        self.inferenceSteps = inferenceSteps
        self.guidanceScale = guidanceScale
        self.aspectRatio = aspectRatio
    }
}

enum ImageAspectRatio: String {
    case landscape = "16:9"
    case portrait = "9:16"
    case square = "1:1"
}

class ReplicateService {
    private let client: Replicate.Client
    private let faceRestorationModelVersion = "9283608cc6b7be6b65a8e44983db012355fde4132009bf99d976b2f0896856a3"
    
    init(apiToken: String) {
        print("Initializing ReplicateService with token: \(apiToken.prefix(5))...")
        self.client = Replicate.Client(token: apiToken)
    }
    
    func runImageGeneration(prompt: String, aspectRatio: ImageAspectRatio = .square) async throws -> ImageGenerationResult? {
        print("Starting image generation with prompt: \(prompt)")
        let model = try await client.getModel("stability-ai/stable-diffusion-3")
        print("Model retrieved successfully")
        
        if let latestVersion = model.latestVersion {
            print("Using model version: \(latestVersion.id)")
            
            let defaults = UserDefaults.standard
            let qualitySettings = defaults.dictionary(forKey: "replicateSettings") ?? [:]
            print("Quality settings: \(qualitySettings)")
            
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
            
            print("Final input parameters: \(input)")
            
            let prediction = try await client.createPrediction(
                version: latestVersion.id,
                input: input
            )
            print("Prediction created with ID: \(prediction.id)")
            
            var currentPrediction = prediction
            repeat {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                currentPrediction = try await client.getPrediction(id: prediction.id)
                print("Prediction status: \(currentPrediction.status.rawValue)")
                
                if let error = currentPrediction.error {
                    print("Prediction error received: \(error)")
                    throw NSError(domain: "ReplicateService", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: error])
                }
                
            } while currentPrediction.status.rawValue == "starting" ||
            currentPrediction.status.rawValue == "processing"
            
            print("Processing complete")
            
            if let output = currentPrediction.output {
                print("Raw output received: \(output)")
                if case let .array(values) = output,
                   let firstOutput = values.first,
                   case let .string(urlString) = firstOutput {
                    print("Generated URL: \(urlString)")
                    guard let outputURL = URL(string: urlString) else { return nil }
                    
                    let metadata = ImageMetadata(
                        inferenceSteps: {
                            if case let .int(steps) = input["num_inference_steps"] {
                                return steps
                            }
                            return 30
                        }(),
                        guidanceScale: {
                            if case let .double(scale) = input["guidance_scale"] {
                                return scale
                            }
                            return 7.5
                        }(),
                        aspectRatio: aspectRatio.rawValue
                    )
                    return ImageGenerationResult(url: outputURL, metadata: metadata)
                }
            }
            
            print("No valid output found in prediction response")
        } else {
            print("No latest version found for model")
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
