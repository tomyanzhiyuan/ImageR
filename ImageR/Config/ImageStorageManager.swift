//
//  ImageStorageManager.swift
//  ImageR
//
//  Created by Tom Yan Zhiyuan on 01/12/2024.
//

import Foundation

public struct ImageSize: Codable {
    public let width: Int
    public let height: Int
    
    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
}

public struct GeneratedImage: Identifiable, Codable {
    public let id: UUID
    public let url: URL
    public let prompt: String?
    public let createdAt: Date
    public let type: ImageType
    public let size: ImageSize?
    
    public enum ImageType: String, Codable {
        case generated
        case restored
    }
    
    public init(url: URL, prompt: String? = nil, type: ImageType, size: ImageSize? = nil) {
        self.id = UUID()
        self.url = url
        self.prompt = prompt
        self.createdAt = Date()
        self.type = type
        self.size = size
    }
}

public class ImageStorageManager: ObservableObject {
    @Published public var savedImages: [GeneratedImage] = []
    private let userDefaults = UserDefaults.standard
    private let saveKey = "savedImages"
    
    public init() {
        loadImages()
    }
    
    func saveImage(_ image: GeneratedImage) {
        savedImages.append(image)
        saveToStorage()
    }
    
    func deleteImage(_ image: GeneratedImage) {
        savedImages.removeAll { $0.id == image.id }
        saveToStorage()
    }
    
    private func loadImages() {
        if let data = userDefaults.data(forKey: saveKey),
           let decodedImages = try? JSONDecoder().decode([GeneratedImage].self, from: data) {
            savedImages = decodedImages
        }
    }
    
    private func saveToStorage() {
        if let encoded = try? JSONEncoder().encode(savedImages) {
            userDefaults.set(encoded, forKey: saveKey)
        }
    }
}
