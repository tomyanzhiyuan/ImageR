//
//  ImageRApp.swift
//  ImageR
//
//  Created by Tom Yan Zhiyuan on 01/12/2024.
//

import SwiftUI

@main
struct ImageRApp: App {
    @StateObject private var settingsManager = SettingsManager()
    let apiToken = "r8_KLMcq2x2iwXa26pvRPey7QyspwuCpje1KNftO"
    
    var body: some Scene {
        WindowGroup {
            ContentView(apiToken: apiToken)
        }
    }
}
