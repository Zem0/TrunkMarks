//
//  AccountGroupView.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 08/04/2025.
//

import SwiftUI

struct AccountGroupView: View {
    let groupedPosts: [Account: [Status]]
    let instanceDomain: String
    @ObservedObject var bookmarksViewModel: BookmarksViewModel
    let accessToken: String
    @ObservedObject var emojiViewModel: EmojiViewModel
    
    // Store the raw value directly rather than using a computed property
    @AppStorage("accountSortOption") private var sortOptionRawValue = SortOption.nameAscending.rawValue
    
    // Define sort options
    enum SortOption: String, CaseIterable, Identifiable {
        case nameAscending = "Name (A-Z)"
        case nameDescending = "Name (Z-A)"
        case postsDescending = "Most Bookmarks"
        case postsAscending = "Least Bookmarks"
        
        var id: String { self.rawValue }
    }
    
    // Computed property that returns sorted accounts based on the selected sort option
    private var sortedAccounts: [Account] {
        let accounts = Array(groupedPosts.keys)
        let currentSortOption = SortOption(rawValue: sortOptionRawValue) ?? .nameAscending
        
        switch currentSortOption {
        case .nameAscending:
            return accounts.sorted { $0.display_name.lowercased() < $1.display_name.lowercased() }
            
        case .nameDescending:
            return accounts.sorted { $0.display_name.lowercased() > $1.display_name.lowercased() }
            
        case .postsDescending:
            return accounts.sorted {
                guard let posts1 = groupedPosts[$0], let posts2 = groupedPosts[$1] else { return false }
                return posts1.count > posts2.count
            }
            
        case .postsAscending:
            return accounts.sorted {
                guard let posts1 = groupedPosts[$0], let posts2 = groupedPosts[$1] else { return false }
                return posts1.count < posts2.count
            }
        }
    }
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(sortedAccounts.enumerated()), id: \.element) { index, account in
                        if let posts = groupedPosts[account] {
                            let isFirst = index == 0
                            let isLast = index == sortedAccounts.count - 1
                            let corners: UIRectCorner = {
                                if isFirst && isLast { return .allCorners }
                                if isFirst { return [.topLeft, .topRight] }
                                if isLast { return [.bottomLeft, .bottomRight] }
                                return []
                            }()
                            
                            VStack(spacing: 0) {
                                NavigationLink(destination: AccountPostsView(
                                    account: account,
                                    posts: posts,
                                    instanceDomain: instanceDomain,
                                    bookmarksViewModel: bookmarksViewModel,
                                    accessToken: accessToken,
                                    emojiViewModel: emojiViewModel
                                )) {
                                    HStack(spacing: 12) {
                                        // Avatar using AsyncImage
                                        AsyncImage(url: URL(string: account.avatar)) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            case .failure:
                                                Image(systemName: "person.circle.fill")
                                                    .foregroundColor(.gray)
                                            @unknown default:
                                                Image(systemName: "person.circle.fill")
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 15))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                                                .shadow(color: Color(.black.opacity(0.6)), radius: 1, x: 0, y: 1)
                                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                        )
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(account.display_name)
                                                .font(.headline)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                            Text("@\(account.username)")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                            HStack {
                                                Image(systemName: "bookmark.fill")
                                                Text("\(posts.count) bookmark\(posts.count == 1 ? "" : "s")")
                                            }
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        Color(.secondarySystemGroupedBackground)
                                            .clipShape(RoundedCornerShape(radius: 12, corners: corners))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Add custom divider after each item except the last
                                if !isLast {
                                    Rectangle()
                                        .fill(Color(.separator).opacity(0.5))
                                        .frame(height: 0.5)
                                        .padding(.leading, 78) // Align with content after avatar
                                        .padding(.trailing, 0)
                                        .background(Color(.secondarySystemGroupedBackground))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 20)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
        .navigationTitle("Bookmarks")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    // Create a Picker that directly modifies the sortOptionRawValue
                    ForEach(SortOption.allCases) { option in
                        Button(action: {
                            sortOptionRawValue = option.rawValue
                        }) {
                            HStack {
                                Text(option.rawValue)
                                if sortOptionRawValue == option.rawValue {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
            }
        }
        .fontDesign(.rounded)
        .onAppear {
            // Check if we should fetch emoji
            if emojiViewModel.isCacheStale(for: instanceDomain) {
                emojiViewModel.fetchCustomEmoji(for: instanceDomain)
            }
        }
    }
}

// Image caching system
class ImageCache: ObservableObject {
    private var cache = NSCache<NSString, UIImage>()
    
    func get(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }
    
    func set(image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

struct CachedAsyncImage: View {
    let url: URL?
    let cache: ImageCache
    
    @State private var image: UIImage? = nil
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard !isLoading, image == nil, let url = url else { return }
        
        // Check if the image is already in the cache
        if let cachedImage = cache.get(forKey: url.absoluteString) {
            self.image = cachedImage
            return
        }
        
        // Start loading
        isLoading = true
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { DispatchQueue.main.async { self.isLoading = false } }
            
            guard let data = data, error == nil,
                  let loadedImage = UIImage(data: data) else {
                return
            }
            
            // Store in cache and update image
            DispatchQueue.main.async {
                cache.set(image: loadedImage, forKey: url.absoluteString)
                self.image = loadedImage
            }
        }.resume()
    }
}

#Preview {
    NavigationStack {
        AccountGroupView(
            groupedPosts: [
                PreviewData.sampleAccount: PreviewData.sampleStatuses,
                PreviewData.createAccount(username: "user2", displayName: "Another User"):
                    [PreviewData.createSampleStatus(id: "123", content: "<p>Sample content</p>")]
            ],
            instanceDomain: "mastodon.social",
            bookmarksViewModel: BookmarksViewModel(),
            accessToken: "preview_token",
            emojiViewModel: EmojiViewModel()
        )
    }
}

// Add this helper to PreviewData if needed
extension PreviewData {
    static func createAccount(username: String, displayName: String) -> Account {
        Account(
            username: username,
            display_name: displayName,
            avatar: "PreviewAvatar",
            acct: username,
            url: "https://mastodon.social/@\(username)"
        )
    }
}
