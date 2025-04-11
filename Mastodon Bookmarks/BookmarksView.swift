//
//  BookmarksView.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 06/04/2025.
//

import SwiftUI

struct BookmarksView: View {
    @ObservedObject var bookmarksViewModel: BookmarksViewModel
    let instanceURL: String
    let accessToken: String
    @ObservedObject var emojiViewModel: EmojiViewModel
    
    // Extract the domain from the instance URL
    private var instanceDomain: String {
        instanceURL.replacingOccurrences(of: "https://", with: "")
                  .replacingOccurrences(of: "http://", with: "")
    }
    
    // Pre-compute grouped posts to simplify the view body
    private var groupedByAccount: [Account: [Status]] {
        Dictionary(grouping: bookmarksViewModel.bookmarks) { $0.account }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if bookmarksViewModel.isLoading {
                    VStack {
                        ProgressView("Loading bookmarks...")
                        
                        Text(String(format: "%.0f%%", bookmarksViewModel.loadingProgress * 100))
                            .font(.caption)
                            .padding(.top)
                    }
                } else if bookmarksViewModel.bookmarks.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bookmark.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Bookmarks")
                            .font(.headline)
                        
                        Text("You don't have any bookmarks yet. Bookmarks you add in Mastodon will appear here.")
                            .multilineTextAlignment(.center)
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    // Use the pre-computed groupedByAccount
                    AccountGroupView(
                        groupedPosts: groupedByAccount,
                        instanceDomain: instanceDomain,
                        bookmarksViewModel: bookmarksViewModel,
                        accessToken: accessToken,
                        emojiViewModel: emojiViewModel
                    )
                }
            }
            .refreshable {
                await refreshBookmarks()
            }
            .navigationTitle("Bookmarks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        bookmarksViewModel.fetchAllBookmarks(instanceURL: instanceURL, token: accessToken)
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            // Set emoji view model on the bookmarks view model
            bookmarksViewModel.setEmojiViewModel(emojiViewModel)
            
            // Load bookmarks if not already loaded
            if bookmarksViewModel.bookmarks.isEmpty && !bookmarksViewModel.isLoading {
                bookmarksViewModel.loadBookmarks(instanceURL: instanceURL, token: accessToken)
            }
            
            // Fetch emoji for the instance domain
            if emojiViewModel.isCacheStale(for: instanceDomain) {
                emojiViewModel.fetchCustomEmoji(for: instanceDomain)
            }
        }
    }
    
    // Function to refresh bookmarks (used by pull-to-refresh)
    private func refreshBookmarks() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                bookmarksViewModel.pullToRefresh(instanceURL: instanceURL, token: accessToken)
                continuation.resume()
            }
        }
    }
}
