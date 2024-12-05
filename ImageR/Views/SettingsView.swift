//
//  SettingsView.swift
//  ImageR
//
//  Created by Tom Yan Zhiyuan on 01/12/2024.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @ObservedObject private var storageManager = ImageStorageManager.shared
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Generation Settings")) {
                    Stepper(
                        "Images per Generation: \(settingsManager.imagesPerGeneration)",
                        value: $settingsManager.imagesPerGeneration,
                        in: 1...4
                    )
                    .help("Generate multiple images at once (may take longer)")
                    
                    Toggle("Auto-save to Photos", isOn: $settingsManager.autoSaveToPhotos)
                        .help("Automatically save generated images to your photo library")
                }
                
                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: $settingsManager.theme) {
                        Text("System").tag(0)
                        Text("Light").tag(1)
                        Text("Dark").tag(2)
                    }
                    .onChange(of: settingsManager.theme) { _, _ in
                        settingsManager.applyTheme()
                    }
                }
                
                
                Section(header: Text("Storage Management"), footer: Text("This action cannot be undone")) {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear All Generated Images")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Delete All Images?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All", role: .destructive) {
                    ImageStorageManager.shared.savedImages.removeAll()
                    ImageStorageManager.shared.saveToStorage()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will remove all generated images from the app. This action cannot be undone.")
            }
        }
    }
}
