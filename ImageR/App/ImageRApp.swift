//
//  ImageRApp.swift
//  ImageR
//
//  Created by Tom Yan Zhiyuan on 01/12/2024.
//

import SwiftUI
import Photos
import UIKit

@main
struct ImageRApp: App {
    @StateObject private var settingsManager = SettingsManager()
    let apiToken = "r8_KLMcq2x2iwXa26pvRPey7QyspwuCpje1KNftO"
    
    init() {
        // Request photo library permissions at launch
        Task {
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            print("Photo library authorization status: \(status.rawValue)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(apiToken: apiToken)
                .onAppear {
                    // Request permissions when app appears
                    Task {
                        _ = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                    }
                }
        }
    }
}
