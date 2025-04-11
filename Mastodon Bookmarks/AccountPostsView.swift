//
//  AccountPostsView.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 08/04/2025.
//

import SwiftUI

struct AccountPostsView: View {
    let account: Account
    let posts: [Status]
    let instanceDomain: String
    @ObservedObject var bookmarksViewModel: BookmarksViewModel
    let accessToken: String
    @ObservedObject var emojiViewModel: EmojiViewModel
    
    // Share the same image cache
    @EnvironmentObject private var imageCache: ImageCache
    
    // Track emoji fetches
    @State private var hasCheckedEmoji = false
    
    var body: some View {
        VStack {
            List(posts) { status in
                NavigationLink(destination: BookmarkDetailView(
                    status: status,
                    instanceDomain: instanceDomain,
                    emojiViewModel: emojiViewModel
                )) {
                    VStack(alignment: .leading, spacing: 8) {
                        // Account info with avatar
                        HStack(spacing: 8) {
                            // Use cached image
                            CachedAsyncImage(
                                url: URL(string: status.account.avatar),
                                cache: imageCache
                            )
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            
                            // Account info
                            VStack(alignment: .leading, spacing: 2) {
                                Text(status.account.display_name)
                                    .font(.headline)
                                
                                Text("@\(status.account.username)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Post content - simple text without emoji support for now
                        Text(formatContent(status.content.stripHTML()))
                            .font(.body)
                            .lineLimit(3)
                            .padding(.vertical, 2)
                        
                        // Media attachments indicator
                        if !status.media_attachments.isEmpty {
                            HStack {
                                Image(systemName: "photo")
                                Text("\(status.media_attachments.count) media attachment\(status.media_attachments.count > 1 ? "s" : "")")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .refreshable {
                // Pull-to-refresh implementation
                await refreshBookmarks()
            }
            .listStyle(.inset)
            .overlay(
                Group {
                    if bookmarksViewModel.isRefreshing {
                        VStack {
                            Spacer().frame(height: 50)
                            HStack {
                                Spacer()
                                ProgressView("Checking for new bookmarks...")
                                    .padding()
                                    .background(Color(UIColor.systemBackground))
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }
            )
        }
        .navigationTitle(account.display_name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Check emoji only once per view lifecycle
            if !hasCheckedEmoji {
                if emojiViewModel.isCacheStale(for: instanceDomain) {
                    emojiViewModel.fetchCustomEmoji(for: instanceDomain)
                }
                hasCheckedEmoji = true
            }
        }
    }
    
    // Format content to clean up URLs
    private func formatContent(_ content: String) -> String {
        // Regular expression to find URLs
        let urlPattern = "(https?://)?([\\w-]+\\.)+[\\w-]+(/[\\w- ./?%&=]*)?"
        let regex = try? NSRegularExpression(pattern: urlPattern, options: [])
        
        var formattedContent = content
        
        // Find all matches and replace them with shortened URLs
        if let matches = regex?.matches(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count)) {
            // Process matches from last to first to avoid changing string indexes
            for match in matches.reversed() {
                if let range = Range(match.range, in: content) {
                    let urlString = String(content[range])
                    
                    // Format the URL for display (remove protocol, truncate if too long)
                    var displayUrl = urlString
                        .replacingOccurrences(of: "https://", with: "")
                        .replacingOccurrences(of: "http://", with: "")
                    
                    // Truncate long URLs
                    if displayUrl.count > 30 {
                        displayUrl = String(displayUrl.prefix(27)) + "..."
                    }
                    
                    // Replace in the string
                    if let formattedRange = Range(match.range, in: formattedContent) {
                        formattedContent = formattedContent.replacingCharacters(in: formattedRange, with: displayUrl)
                    }
                }
            }
        }
        
        return formattedContent
    }
    
    // Function to refresh bookmarks (used by pull-to-refresh)
    private func refreshBookmarks() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                bookmarksViewModel.pullToRefresh(instanceURL: "https://\(instanceDomain)", token: accessToken)
                continuation.resume()
            }
        }
    }
}
