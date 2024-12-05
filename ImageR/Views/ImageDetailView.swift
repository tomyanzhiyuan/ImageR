//
//  ImageDetailView.swift
//  ImageR
//
//  Created by Tom Yan Zhiyuan on 01/12/2024.
//

import Foundation
import SwiftUI

struct ImageDetailView: View {
    let image: GeneratedImage
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var offset = CGSize.zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset = CGSize.zero
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Image display
                    AsyncImage(url: image.url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 300)
                                .scaleEffect(scale)
                                .offset(offset)
                                .gesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            let delta = value / lastScale
                                            lastScale = value
                                            scale *= delta
                                        }
                                        .onEnded { _ in
                                            lastScale = 1.0
                                        }
                                )
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            offset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                        }
                                        .onEnded { _ in
                                            lastOffset = offset
                                        }
                                )
                                .onTapGesture(count: 2) {
                                    withAnimation {
                                        scale = 1.0
                                        offset = .zero
                                        lastOffset = .zero
                                    }
                                }
                        case .failure:
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 50))
                                .foregroundColor(.red)
                        case .empty:
                            ProgressView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                    
                    // Image details
                    VStack(alignment: .leading, spacing: 12) {
                        if image.type == .generated {
                            DetailRow(title: "Prompt", value: image.prompt ?? "No prompt")
                        }
                        
                        DetailRow(title: "Type", value: image.type == .generated ? "AI Generated" : "Face Restored")
                        DetailRow(title: "Created", value: formatDate(image.createdAt))
                        DetailRow(title: "Size", value: "\(image.size.width) x \(image.size.height)")
                        
                        if image.type == .generated {
                            DetailRow(title: "Model", value: "Stable Diffusion v3")
                        }
                        DetailRow(title: "Generation Steps", value: "\(image.inferenceSteps ?? 30)")
                        DetailRow(title: "Guidance Scale", value: String(format: "%.1f", image.guidanceScale ?? 7.5))
                        DetailRow(title: "Aspect Ratio", value: image.aspectRatio ?? "1:1")
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .padding(.horizontal)
                }
            }
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .navigationTitle(image.type == .generated ? "Generated Image" : "Restored Image")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
    }
}
