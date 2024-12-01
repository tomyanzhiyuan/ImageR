//
//  AppInfoView.swift
//  ImageR
//
//  Created by Tom Yan Zhiyuan on 01/12/2024.
//

import SwiftUI

struct AppInfoView: View {
    let title = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "ImageR"
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    InfoRow(title: "App Name", value: title)
                    InfoRow(title: "Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    InfoRow(title: "Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                    InfoRow(title: "Copyright", value: "© 2024")
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

#Preview {
    AppInfoView()
        // Preview with Chinese locale
        .environment(\.locale, .init(identifier: "zh-Hans"))
}
