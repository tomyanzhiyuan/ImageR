//
//  PhotoManager.swift
//  ImageR
//
//  Created by Tom Yan Zhiyuan on 01/12/2024.
//

import Foundation
import Photos
import UIKit
import PhotosUI

class YourViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            // Handle the authorization status
        }
    }
}

class PhotoManager: NSObject {
    static let shared = PhotoManager()
    private var completionHandler: ((Error?) -> Void)?
    
    static func saveToAlbum(url: URL) async throws {
        print("🔍 Attempting to save image from URL: \(url)")
        
        // First check authorization
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard status == .authorized || status == .limited else {
            throw PhotoError.notAuthorized
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let (data, response) = try await URLSession.shared.data(from: url)
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        print("📡 HTTP Status: \(httpResponse.statusCode)")
                        print("📦 Data size: \(data.count) bytes")
                    }
                    
                    // Create UIImage from WebP data
                    guard let image = UIImage(data: data) else {
                        print("❌ Failed to create UIImage from data")
                        continuation.resume(throwing: PhotoError.invalidImageData)
                        return
                    }
                    
                    print("✅ Successfully created UIImage, size: \(image.size)")
                    
                    // Convert to PNG data
                    guard let pngData = image.pngData(),
                          let convertedImage = UIImage(data: pngData) else {
                        print("❌ Failed to convert WebP to PNG")
                        continuation.resume(throwing: PhotoError.invalidImageData)
                        return
                    }
                    
                    print("✅ Successfully converted to PNG")
                    
                    shared.completionHandler = { error in
                        if let error = error {
                            print("❌ Save failed with error: \(error)")
                            continuation.resume(throwing: PhotoError.saveFailed(error))
                        } else {
                            print("💾 Image saved successfully to Photos")
                            continuation.resume()
                        }
                    }
                    
                    DispatchQueue.main.async {
                        UIImageWriteToSavedPhotosAlbum(convertedImage,
                                                     shared,
                                                     #selector(PhotoManager.image(_:didFinishSavingWithError:contextInfo:)),
                                                     nil)
                    }
                } catch {
                    print("❌ Download failed with error: \(error)")
                    continuation.resume(throwing: PhotoError.downloadFailed)
                }
            }
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        completionHandler?(error)
        completionHandler = nil
    }
}

// Update PhotoError to include more specific cases
enum PhotoError: LocalizedError {
    case notAuthorized
    case invalidImageData
    case downloadFailed
    case saveFailed(Error?)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Photo access is not authorized. Please grant access in Settings."
        case .invalidImageData:
            return "The image data could not be processed."
        case .downloadFailed:
            return "Failed to download the image. Please check your internet connection."
        case .saveFailed(let error):
            if let phError = error as? PHPhotosError {
                switch phError.code {
                case .accessUserDenied:
                    return "Access to Photos was denied. Please check your permissions in Settings."
                default:
                    return "Failed to save photo: \(phError.localizedDescription)"
                }
            }
            return error?.localizedDescription ?? "Failed to save to photo library"
        case .unknown:
            return "An unexpected error occurred while saving the photo"
        }
    }
}
