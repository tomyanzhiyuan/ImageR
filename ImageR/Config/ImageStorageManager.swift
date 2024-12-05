//
//  ImageStorageManager.swift
//  ImageR
//
//  Created by Tom Yan Zhiyuan on 01/12/2024.
//

import Foundation
import CoreImage
import CoreGraphics
import UIKit

public class ImageSizeLoader: ObservableObject {
    @Published var size: ImageSize
    
    init(defaultSize: ImageSize = ImageSize(width: 1024, height: 1024)) {
        self.size = defaultSize
    }
    
    func loadSize(from url: URL) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let uiImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.size = ImageSize(
                            width: Int(uiImage.size.width),
                            height: Int(uiImage.size.height)
                        )
                    }
                }
            } catch {
                print("Error loading image size: \(error)")
            }
        }
    }
}

public struct ImageSize: Codable, Equatable {
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
    public var size: ImageSize
    public var inferenceSteps: Int?  // Number of steps used in generation
    public var guidanceScale: Double? // Guidance scale used
    public var aspectRatio: String?   // The aspect ratio used (16:9, 1:1, etc.)
    public var restorationScale: Int? // The scale factor used in restoration
    public var restorationVersion: String? // The version of GFPGAN used
    public let metadata: ImageMetadata

    
    public enum ImageType: String, Codable {
        case generated
        case restored
    }
    
    public init(url: URL, prompt: String? = nil, type: ImageType, metadata: ImageMetadata? = nil) async {
        self.id = UUID()
        self.url = url
        self.prompt = prompt
        self.createdAt = Date()
        self.type = type
        self.metadata = metadata!
        
        // Get image size synchronously
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                self.size = ImageSize(
                    width: Int(uiImage.size.width),
                    height: Int(uiImage.size.height)
                )
            } else {
                self.size = ImageSize(width: 1024, height: 1024)
            }
        } catch {
            print("Error loading image size: \(error)")
            self.size = ImageSize(width: 1024, height: 1024)
        }
    }
}

public class ImageStorageManager: ObservableObject {
    @Published public var savedImages: [GeneratedImage] = []
    private let userDefaults = UserDefaults.standard
    private let saveKey = "savedImages"
    
    public init() {
        loadImages()
    }
    
    public func saveImage(_ image: GeneratedImage) {
        savedImages.append(image)
        saveToStorage()
    }
    
    public func deleteImage(_ image: GeneratedImage) {
        savedImages.removeAll { $0.id == image.id }
        saveToStorage()
    }
    
    public func updateImageSize(_ image: GeneratedImage, newSize: ImageSize) {
        if let index = savedImages.firstIndex(where: { $0.id == image.id }) {
            var updatedImage = savedImages[index]
            updatedImage.size = newSize
            savedImages[index] = updatedImage
            saveToStorage()
        }
    }
    
    private func loadImages() {
        if let data = userDefaults.data(forKey: saveKey),
           let decodedImages = try? JSONDecoder().decode([GeneratedImage].self, from: data) {
            savedImages = decodedImages
            
            // Reload sizes for all images
            for image in savedImages {
                let sizeLoader = ImageSizeLoader()
                sizeLoader.loadSize(from: image.url)
            }
        }
    }
    
    public func saveToStorage() {
        if let encoded = try? JSONEncoder().encode(savedImages) {
            userDefaults.set(encoded, forKey: saveKey)
        }
    }
}

// Extension to handle size updates
extension NotificationCenter {
    static func postSizeUpdate(_ size: ImageSize, for imageID: UUID) {
        NotificationCenter.default.post(
            name: NSNotification.Name("ImageSizeUpdated"),
            object: nil,
            userInfo: [
                "size": size,
                "imageID": imageID
            ]
        )
    }
}
