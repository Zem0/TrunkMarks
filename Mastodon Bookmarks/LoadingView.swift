//
//  LoadingView.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 09/04/2025.
//

import SwiftUI

struct LoadingView: View {
    let progress: Double
    let message: String
    
    var body: some View {
        VStack(spacing: 24) {
            // SF Symbol animation
            Image(systemName: "bookmark.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .symbolEffect(.bounce, options: .repeating)
            
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .frame(width: 200)
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(radius: 10)
        )
    }
}
