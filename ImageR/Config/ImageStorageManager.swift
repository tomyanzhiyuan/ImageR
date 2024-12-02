//
//  ImageStorageManager.swift
//  ImageR
//
//  Created by Tom Yan Zhiyuan on 01/12/2024.
//

import Foundation

struct GeneratedImage: Identifiable, Codable {
    let id: UUID
    let url: URL
    let prompt: String?
    let createdAt: Date
    let type: ImageType
    
    enum ImageType: String, Codable {
        case generated
        case restored
    }
    
    init(url: URL, prompt: String? = nil, type: ImageType) {
        self.id = UUID()
        self.url = url
        self.prompt = prompt
        self.createdAt = Date()
        self.type = type
    }
}

class ImageStorageManager: ObservableObject {
    @Published var savedImages: [GeneratedImage] = []
    private let userDefaults = UserDefaults.standard
    private let saveKey = "savedImages"
    
    init() {
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
