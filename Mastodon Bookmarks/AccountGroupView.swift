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
        List {
            ForEach(sortedAccounts, id: \.self) { account in
                if let posts = groupedPosts[account] {
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
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(account.display_name)
                                    .font(.headline)
                                Text("@\(account.username)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                HStack {
                                    Image(systemName: "bookmark.fill")
                                    Text("\(posts.count) bookmark\(posts.count == 1 ? "" : "s")")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(.inset)
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
