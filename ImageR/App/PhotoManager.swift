//
//  PhotoManager.swift
//  ImageR
//
//  Created by Tom Yan Zhiyuan on 01/12/2024.
//

import Foundation
import Photos
import UIKit

class PhotoManager {
    static func saveToAlbum(url: URL) async throws {
        // First check authorization status
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .notDetermined {
            let granted = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard granted == .authorized else { throw PhotoError.notAuthorized }
        }
        
        guard status == .authorized else { throw PhotoError.notAuthorized }
        
        // Download the image data
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw PhotoError.invalidImageData
        }
        
        // Save to photo library
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
}

enum PhotoError: Error {
    case notAuthorized
    case invalidImageData
    
    var description: String {
        switch self {
        case .notAuthorized:
            return "Please allow access to Photos in Settings to save images"
        case .invalidImageData:
            return "Unable to process this image"
        }
    }
}
