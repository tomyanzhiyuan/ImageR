//
//  AppInfoView.swift
//  ImageR
//
//  Created by Tom Yan Zhiyuan on 01/12/2024.
//

import Foundation
import SwiftUI

struct AppInfoView: View {
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Spacer()
                        Image("AppIcon")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .cornerRadius(20)
                            .padding()
                        Spacer()
                    }
                }
                
                Section {
                    InfoRow(title: "App Name", value: Bundle.main.appName)
                    InfoRow(title: "Version", value: Bundle.main.appVersion)
                    InfoRow(title: "Build", value: Bundle.main.buildNumber)
                    InfoRow(title: "Copyright", value: "© 2024 Your Name")
                }
            }
            .navigationTitle("App Info")
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
        }
    }
}
