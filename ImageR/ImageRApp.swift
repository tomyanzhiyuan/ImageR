//
//  ImageRApp.swift
//  ImageR
//
//  Created by Tom Yan Zhiyuan on 01/12/2024.
//

// AIImageGeneratorApp.swift
import SwiftUI

@main
struct ImageRApp: App {
    @StateObject private var settingsManager = SettingsManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsManager)
        }
    }
}
