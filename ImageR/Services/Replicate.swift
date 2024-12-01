//
//  Replicate.swift
//  ImageR
//
//  Created by Tom Yan Zhiyuan on 01/12/2024.
//

import Foundation

enum ReplicateError: Error {
    case invalidURL
    case invalidResponse
    case noData
    case decodingError
    case apiError(String)
}

struct PredictionResponse: Codable {
    let id: String
    let status: String
    let output: [String]?
    let error: String?
}

class ReplicateService {
    private let apiToken: String
    private let baseURL = "https://api.replicate.com/v1"
    
    init(apiToken: String) {
        self.apiToken = apiToken
    }
    
    // MARK: - Models
    
    func runDisposableCamera(prompt: String) async throws -> PredictionResponse {
        let modelVersion = "levelsio/disposable-camera:4c8511f55da3561433a89774d0a5c5281594772ecc83130a52c07c6f72a4e550"
        let input = [
            "prompt": prompt,
            "num_outputs": 4,
            "aspect_ratio": "16:9",
            "guidance_scale": 3.5,
            "extra_lora_scale": 0.8
        ] as [String: Any]
        
        return try await runModel(version: modelVersion, input: input)
    }
    
    func runFaceRestoration(imageURL: String) async throws -> PredictionResponse {
        let modelVersion = "tencentarc/gfpgan:9283608cc6b7be6b65a8e44983db012355fde4132009bf99d976b2f0896856a3"
        let input = ["img": imageURL]
        
        return try await runModel(version: modelVersion, input: input)
    }
    
    // MARK: - Private Methods
    
    private func runModel(version: String, input: [String: Any]) async throws -> PredictionResponse {
        guard let url = URL(string: "\(baseURL)/predictions") else {
            throw ReplicateError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Token \(apiToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "version": version,
            "input": input
        ] as [String: Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReplicateError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw ReplicateError.apiError("Status code: \(httpResponse.statusCode)")
        }
        
        let prediction = try JSONDecoder().decode(PredictionResponse.self, from: data)
        return prediction
    }
    
    func checkPrediction(id: String) async throws -> PredictionResponse {
        guard let url = URL(string: "\(baseURL)/predictions/\(id)") else {
            throw ReplicateError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.addValue("Token \(apiToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReplicateError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ReplicateError.apiError("Status code: \(httpResponse.statusCode)")
        }
        
        let prediction = try JSONDecoder().decode(PredictionResponse.self, from: data)
        return prediction
    }
}
