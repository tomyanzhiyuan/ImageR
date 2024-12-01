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
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("API Configuration")) {
                    SecureField("API Key", text: $settingsManager.apiKey)
                }
                
                Section(header: Text("Preferences")) {
                    Picker("Default Model", selection: $settingsManager.defaultModel) {
                        Text("Disposable Camera").tag(0)
                        Text("Face Restoration").tag(1)
                    }
                    
                    Picker("Theme", selection: $settingsManager.theme) {
                        Text("System").tag(0)
                        Text("Light").tag(1)
                        Text("Dark").tag(2)
                    }
                    
                    Picker("Image Quality", selection: $settingsManager.imageQuality) {
                        Text("Low").tag(0)
                        Text("Medium").tag(1)
                        Text("High").tag(2)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
