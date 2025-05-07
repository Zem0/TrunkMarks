//
//  AccountPostsView.swift
//  Mastodon Bookmarks
//

import SwiftUI

// Extract the post row into a separate view component
struct PostRowView: View {
    let post: Status
    let index: Int
    let isFirst: Bool
    let isLast: Bool
    let isShortContent: Bool
    let instanceDomain: String
    @ObservedObject var emojiViewModel: EmojiViewModel
    @EnvironmentObject var folderViewModel: FolderViewModel
    
    var corners: UIRectCorner {
        if isFirst && isLast { return .allCorners }
        if isFirst { return [.topLeft, .topRight] }
        if isLast { return [.bottomLeft, .bottomRight] }
        return []
    }
    
    var body: some View {
        VStack(spacing: 0) {
            NavigationLink(destination: BookmarkDetailView(
                status: post,
                instanceDomain: instanceDomain,
                emojiViewModel: emojiViewModel
            )
            .environmentObject(folderViewModel)) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top, spacing: 4) {
                        SmallBlueSquare(number: index + 1,
                          size: 30,
                          cornerRadius: 9,
                          fontSize: 18)
                        Spacer()
                        postContentView
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    Color(.secondarySystemGroupedBackground)
                        .clipShape(RoundedCornerShape(radius: 12, corners: corners))
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            if !isLast {
                Rectangle()
                    .fill(Color(.separator).opacity(0.5))
                    .frame(height: 0.5)
                    .padding(.leading, 64)
                    .padding(.trailing, 0)
                    .background(Color(.secondarySystemGroupedBackground))
            }
        }
        .padding(.bottom, 0)
    }
    
    // Toot content
    private var postContentView: some View {
        VStack(alignment: .leading) {
            HTMLToSwiftUIView(
                htmlContent: post.content,
                lineLimit: 3
            )
            
            if !post.media_attachments.isEmpty {
                Spacer()
                HStack {
                    Image(systemName: "photo")
                    Text("\(post.media_attachments.count) media attachment\(post.media_attachments.count > 1 ? "s" : "")")
                }
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// Main view
struct AccountPostsView: View {
    let account: Account
    let posts: [Status]
    let instanceDomain: String
    @ObservedObject var bookmarksViewModel: BookmarksViewModel
    let accessToken: String
    @ObservedObject var emojiViewModel: EmojiViewModel
    @EnvironmentObject var folderViewModel: FolderViewModel
    
    @State private var processedPosts = Set<String>()
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(posts.enumerated()), id: \.element.id) { index, post in
                        let isFirst = index == 0
                        let isLast = index == posts.count - 1
                        let strippedContent = post.content.stripHTML()
                        let isShortContent = strippedContent.count < 50 && !strippedContent.contains("\n")
                        
                        PostRowView(
                            post: post,
                            index: index,
                            isFirst: isFirst,
                            isLast: isLast,
                            isShortContent: isShortContent,
                            instanceDomain: instanceDomain,
                            emojiViewModel: emojiViewModel
                        )
                        .fontDesign(.rounded)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 20)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
                
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .refreshable {
                await refreshBookmarks()
            }
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                accountHeaderView
            }
        }
        .onAppear {
            if emojiViewModel.isCacheStale(for: instanceDomain) {
                emojiViewModel.fetchCustomEmoji(for: instanceDomain)
            }
        }
    }
    

    private var accountHeaderView: some View {
        HStack(spacing: 8) {
            AsyncImage(url: URL(string: account.avatar)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    if account.avatar.contains("preview-") {
                        Image(account.avatar)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Image(systemName: "person.circle.fill")
                    }
                @unknown default:
                    Image(systemName: "person.circle.fill")
                }
            }
            .frame(width: 30, height: 30)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                    .shadow(color: Color(.black.opacity(0.6)), radius: 0.7, x: 0, y: 0.7)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            )
            
            Text(account.display_name)
                .font(.system(.headline, design: .rounded))
        }
    }
    
    private func refreshBookmarks() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                bookmarksViewModel.pullToRefresh(instanceURL: "https://\(instanceDomain)", token: accessToken)
                continuation.resume()
            }
        }
    }
}

#Preview {
    NavigationStack {
        AccountPostsView(
            account: PreviewData.sampleAccount,
            posts: PreviewData.sampleStatuses,
            instanceDomain: "mastodon.social",
            bookmarksViewModel: BookmarksViewModel(),
            accessToken: "preview_token",
            emojiViewModel: EmojiViewModel()
        )
        .environmentObject(FolderViewModel())
    }
}
