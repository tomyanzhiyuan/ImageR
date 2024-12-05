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
    
    // Generation Settings
    @AppStorage("imagesPerGeneration") var imagesPerGeneration: Int = 1
    @AppStorage("autoSaveToPhotos") var autoSaveToPhotos: Bool = false
    
    // App Preferences
    @AppStorage("theme") var theme: Int = 0 // 0: System, 1: Light, 2: Dark
    
    // MARK: - Computed Properties
    
    var colorScheme: ColorScheme? {
        switch theme {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }
    
    // MARK: - Public Methods
    
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
    
    func clearAllStoredImages() {
        let storage = ImageStorageManager()
        storage.savedImages.removeAll()
        storage.saveToStorage()
    }
}

// MARK: - Settings Key Constants
extension SettingsManager {
    struct SettingsKeys {
        static let apiKey = "apiKey"
        static let theme = "theme"
        static let imagesPerGeneration = "imagesPerGeneration"
        static let autoSaveToPhotos = "autoSaveToPhotos"
    }
}
