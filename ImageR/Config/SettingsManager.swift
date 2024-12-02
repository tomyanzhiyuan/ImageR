//
//  SettingsManager.swift
//  ImageR
//
//  Created by Tom Yan Zhiyuan on 01/12/2024.
//

import Foundation
import SwiftUI

class SettingsManager: ObservableObject {
    // Core settings that actually affect the app
    @AppStorage("imageQuality") var imageQuality: Int = 1 {
        didSet {
            updateReplicateSettings()
        }
    }
    
    @AppStorage("theme") var theme: Int = 0 {
        didSet {
            applyTheme()
        }
    }
    
    @AppStorage("autoSave") var autoSave: Bool = true
    
    @AppStorage("maxImages") var maxImages: Int = 50 {
        didSet {
            cleanupStorageIfNeeded()
        }
    }
    
    private func updateReplicateSettings() {
        // Map quality settings to actual API parameters
        let qualitySettings: [String: Any] = [
            "num_inference_steps": imageQuality == 0 ? 20 : (imageQuality == 1 ? 30 : 50),
            "guidance_scale": imageQuality == 0 ? 7.0 : (imageQuality == 1 ? 7.5 : 8.0),
        ]
        UserDefaults.standard.set(qualitySettings, forKey: "replicateSettings")
    }
    
    private func applyTheme() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        switch theme {
        case 1: // Light
            window.overrideUserInterfaceStyle = .light
        case 2: // Dark
            window.overrideUserInterfaceStyle = .dark
        default: // System
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
    
    private func cleanupStorageIfNeeded() {
        let storage = ImageStorageManager.shared
        if storage.savedImages.count > maxImages {
            // Remove oldest images to meet the limit
            let numberToRemove = storage.savedImages.count - maxImages
            let oldestImages = storage.savedImages.prefix(numberToRemove)
            oldestImages.forEach { storage.deleteImage($0) }
        }
    }
}
