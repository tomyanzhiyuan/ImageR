//
//  SettingsManager.swift
//  ImageR
//
//  Created by Tom Yan Zhiyuan on 01/12/2024.
//

import Foundation
import SwiftUI

class SettingsManager: ObservableObject {
    @AppStorage("apiKey") var apiKey: String = Config.replicateAPIKey
    @AppStorage("defaultModel") var defaultModel: Int = 0 // 0: Disposable, 1: Face Restoration
    @AppStorage("theme") var theme: Int = 0 // 0: System, 1: Light, 2: Dark
    @AppStorage("imageQuality") var imageQuality: Int = 1 // 0: Low, 1: Medium, 2: High
    
    // Theme color (customizable in Assets)
    var accentColor: Color {
        Color("AccentColor")
    }
    
    var secondaryColor: Color {
        Color("CustomSecondaryColor")
    }
}
