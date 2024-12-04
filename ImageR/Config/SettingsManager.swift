//
//  SettingsManager.swift
//  ImageR
//
//  Created by Tom Yan Zhiyuan on 01/12/2024.
//

import Foundation
import SwiftUI

class SettingsManager: ObservableObject {
    // MARK: - Stored Properties with AppStorage
    
    // API Configuration
    @AppStorage("apiKey") var apiKey: String = Config.replicateAPIKey
    
    // Model & Processing Settings
    @AppStorage("defaultModel") var defaultModel: Int = 0 // 0: Disposable, 1: Face Restoration
    @AppStorage("imageQuality") var imageQuality: Int = 1 // 0: Low, 1: Medium, 2: High
    
    // App Preferences
    @AppStorage("theme") var theme: Int = 0 // 0: System, 1: Light, 2: Dark
    @AppStorage("autosaveEnabled") var autosaveEnabled: Bool = true
    @AppStorage("maxStorageImages") var maxStorageImages: Int = 50
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
    
    // MARK: - Computed Properties
    
    var colorScheme: ColorScheme? {
        switch theme {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }
    
    // MARK: - Public Methods
    
    func getQualitySettings() -> [String: Any] {
        switch imageQuality {
        case 0: // Low
            return [
                "num_inference_steps": 20,
                "guidance_scale": 7.0
            ]
        case 2: // High
            return [
                "num_inference_steps": 50,
                "guidance_scale": 8.0
            ]
        default: // Medium
            return [
                "num_inference_steps": 30,
                "guidance_scale": 7.5
            ]
        }
    }
    
    func getCurrentModelId() -> String {
        switch defaultModel {
        case 0:
            return Config.disposableCameraModel
        case 1:
            return Config.faceRestorationModel
        default:
            return Config.disposableCameraModel
        }
    }
    
    func applyTheme() {
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
    
    // MARK: - Storage Management
    
    func cleanupStorageIfNeeded() {
        let storage = ImageStorageManager()
        if storage.savedImages.count > maxStorageImages {
            // Remove oldest images to meet the limit
            let numberToRemove = storage.savedImages.count - maxStorageImages
            let oldestImages = storage.savedImages.prefix(numberToRemove)
            oldestImages.forEach { storage.deleteImage($0) }
        }
    }
}

// MARK: - Settings Key Constants
extension SettingsManager {
    struct SettingsKeys {
        static let apiKey = "apiKey"
        static let defaultModel = "defaultModel"
        static let imageQuality = "imageQuality"
        static let theme = "theme"
        static let autosave = "autosaveEnabled"
        static let maxStorage = "maxStorageImages"
        static let notifications = "notificationsEnabled"
    }
}
