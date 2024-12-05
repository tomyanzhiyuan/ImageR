//
//  ContentView.swift
//  ImageR
//
//  Created by Tom Yan Zhiyuan on 01/12/2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var settingsManager = SettingsManager()
    let apiToken: String
    
    var body: some View {
        TabView {
            ImageGeneratorView(
                viewModel: ImageGeneratorViewModel(
                    apiToken: apiToken,
                    settingsManager: settingsManager
                )
            )
            .tabItem {
                Label("Generate", systemImage: "wand.and.stars")
            }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
            
            AppInfoView()
                .tabItem {
                    Label("Info", systemImage: "info.circle")
                }
        }
        .environmentObject(settingsManager)
    }
}

#Preview {
    ContentView(apiToken: "preview-token")
}
