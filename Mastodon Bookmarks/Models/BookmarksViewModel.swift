//
//  BookmarksViewModel.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 06/04/2025.
//

import Foundation

class BookmarksViewModel: ObservableObject {
    @Published var bookmarks: [Status] = []
    @Published var isLoading = false
    @Published var isRefreshing = false // Separate state for pull-to-refresh
    @Published var isFullyLoaded = false
    @Published var loadingProgress: Double = 0.0
    @Published var errorMessage: String? = nil
    
    // For local storage
    private let bookmarksKey = "cachedBookmarks"
    private let lastFetchDateKey = "lastBookmarksFetchDate"
    private var emojiViewModel: EmojiViewModel?
    
    func setEmojiViewModel(_ viewModel: EmojiViewModel) {
        self.emojiViewModel = viewModel
    }
    
    // Initial load of bookmarks - now with local caching
    func loadBookmarks(instanceURL: String, token: String) {
        // First try to load cached bookmarks
        if loadCachedBookmarks() {
            print("📚 Loaded bookmarks from cache")
            
            // Check if we need to fetch newer bookmarks (silently in background)
            refreshBookmarks(instanceURL: instanceURL, token: token, silent: true)
        } else {
            // No cache or failed to load cache, fetch everything
            print("📡 No cache available, fetching all bookmarks")
            fetchAllBookmarks(instanceURL: instanceURL, token: token)
        }
    }
    
    // Load cached bookmarks from UserDefaults
    private func loadCachedBookmarks() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: bookmarksKey) else {
            print("❌ No cached bookmarks found")
            return false
        }
        
        do {
            let decoder = JSONDecoder()
            let cachedBookmarks = try decoder.decode([Status].self, from: data)
            print("✅ Successfully loaded \(cachedBookmarks.count) bookmarks from cache")
            self.bookmarks = cachedBookmarks
            return true
        } catch {
            print("❌ Failed to decode cached bookmarks: \(error.localizedDescription)")
            return false
        }
    }
    
    // Save bookmarks to UserDefaults
    private func saveBookmarksToCache() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(bookmarks)
            UserDefaults.standard.set(data, forKey: bookmarksKey)
            
            // Save the current date as last fetch date
            UserDefaults.standard.set(Date(), forKey: lastFetchDateKey)
            print("✅ Saved \(bookmarks.count) bookmarks to cache")
        } catch {
            print("❌ Failed to cache bookmarks: \(error.localizedDescription)")
        }
    }
    
    // Public function for pull-to-refresh
    func pullToRefresh(instanceURL: String, token: String) {
        refreshBookmarks(instanceURL: instanceURL, token: token, silent: false)
    }
    
    // Fetch fresh bookmarks and merge with existing ones
    private func refreshBookmarks(instanceURL: String, token: String, silent: Bool) {
        if !silent {
            isRefreshing = true
        }
        
        // Always get the newest bookmarks first
        guard let url = URL(string: "\(instanceURL)/api/v1/bookmarks") else {
            errorMessage = "Invalid URL"
            return
        }
        
        print("🔄 Refreshing bookmarks from \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if !silent {
                    self.isRefreshing = false
                }
                
                if let error = error {
                    print("❌ Error refreshing bookmarks: \(error.localizedDescription)")
                    if !silent {
                        self.errorMessage = "Network error: \(error.localizedDescription)"
                    }
                    return
                }
                
                guard let data = data else {
                    print("❌ No data received when refreshing bookmarks")
                    if !silent {
                        self.errorMessage = "No data received"
                    }
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let newBookmarks = try decoder.decode([Status].self, from: data)
                    print("✅ Successfully decoded \(newBookmarks.count) bookmarks from refresh")
                    
                    // Create a set of existing IDs for quick lookup
                    let existingIds = Set(self.bookmarks.map { $0.id })
                    
                    // Find truly new bookmarks
                    let brandNewBookmarks = newBookmarks.filter { !existingIds.contains($0.id) }
                    
                    if !brandNewBookmarks.isEmpty {
                        print("✅ Found \(brandNewBookmarks.count) new bookmarks")
                        // Insert new bookmarks at the beginning
                        self.bookmarks.insert(contentsOf: brandNewBookmarks, at: 0)
                        // Update cache with the combined list
                        self.saveBookmarksToCache()
                        
                        // Process new bookmarks for emoji
                        if let emojiViewModel = self.emojiViewModel {
                            self.processBookmarks(bookmarks: brandNewBookmarks, emojiViewModel: emojiViewModel)
                        }
                    } else {
                        print("✅ No new bookmarks found during refresh")
                    }
                } catch {
                    print("❌ Failed to decode bookmarks during refresh: \(error.localizedDescription)")
                    if !silent {
                        self.errorMessage = "Failed to decode data: \(error.localizedDescription)"
                    }
                }
            }
        }.resume()
    }
    
    // Load ALL bookmarks (initial and all pagination) then display
    func fetchAllBookmarks(instanceURL: String, token: String) {
        isLoading = true
        isFullyLoaded = false
        loadingProgress = 0.0
        
        guard let url = URL(string: "\(instanceURL)/api/v1/bookmarks") else {
            errorMessage = "Invalid URL"
            return
        }
        
        // First reset any existing data
        bookmarks = []
        var allBookmarks: [Status] = []
        
        // Use recursive function to fetch all pages
        fetchAllPages(url: url, token: token, allBookmarks: allBookmarks)
    }
    
    // Recursive function to fetch all pages
    private func fetchAllPages(url: URL, token: String, allBookmarks: [Status], pageCount: Int = 1) {
        print("📡 Fetching page \(pageCount) from: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("❌ Error fetching bookmarks: \(error.localizedDescription)")
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                }
                return
            }
            
            var nextURL: URL? = nil
            
            // Check for pagination links in header
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 Response status code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "Server returned status code: \(httpResponse.statusCode)"
                    }
                    return
                }
                
                // Parse Link header for pagination
                if let linkHeader = httpResponse.allHeaderFields["Link"] as? String {
                    nextURL = self.extractNextPageURL(from: linkHeader)
                }
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("❌ No data received from server.")
                    self.errorMessage = "No data received"
                }
                return
            }
            
            self.debugDecodeBookmarks(from: data)
            
            do {
                let decoder = JSONDecoder()
                let decodedBookmarks = try decoder.decode([Status].self, from: data)
                print("✅ Successfully decoded \(decodedBookmarks.count) bookmarks from page \(pageCount)")
                
                // Add the new bookmarks to our collection
                var updatedBookmarks = allBookmarks
                updatedBookmarks.append(contentsOf: decodedBookmarks)
                
                // Update loading progress (estimate based on items per page)
                let itemsPerPage = decodedBookmarks.count
                let progress = itemsPerPage > 0 ? min(0.9, Double(updatedBookmarks.count) / Double(updatedBookmarks.count + itemsPerPage)) : 0.9
                
                DispatchQueue.main.async {
                    self.loadingProgress = progress
                }
                
                // If we have more pages, continue fetching
                if let nextURL = nextURL, !decodedBookmarks.isEmpty {
                    // Give UI a chance to update with progress
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.fetchAllPages(url: nextURL, token: token, allBookmarks: updatedBookmarks, pageCount: pageCount + 1)
                    }
                } else {
                    // We're done! Save all bookmarks and update UI
                    DispatchQueue.main.async {
                        self.bookmarks = updatedBookmarks
                        self.isLoading = false
                        self.isFullyLoaded = true
                        self.loadingProgress = 1.0
                        print("✅ Finished loading all \(updatedBookmarks.count) bookmarks")
                        
                        // Cache the bookmarks
                        self.saveBookmarksToCache()
                        
                        // Process bookmarks for emoji
                        if let emojiViewModel = self.emojiViewModel {
                            self.processBookmarks(bookmarks: updatedBookmarks, emojiViewModel: emojiViewModel)
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("❌ Failed to decode bookmarks: \(error.localizedDescription)")
                    
                    // Try to print the raw JSON for debugging
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("📄 Raw JSON response: \(jsonString)")
                    }
                    
                    self.errorMessage = "Failed to decode data: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    // Extract the next page URL from the Link header
    private func extractNextPageURL(from header: String) -> URL? {
        let links = header.components(separatedBy: ",")
        
        for link in links {
            let components = link.components(separatedBy: ";")
            guard components.count >= 2 else { continue }
            
            let urlString = components[0].trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: "<", with: "")
                .replacingOccurrences(of: ">", with: "")
            
            let rel = components[1].trimmingCharacters(in: .whitespaces)
            
            if rel.contains("next") {
                print("📄 Found next page URL: \(urlString)")
                return URL(string: urlString)
            }
        }
        
        return nil
    }
    
    func processBookmarks(bookmarks: [Status], emojiViewModel: EmojiViewModel) {
        // Extract unique domains from bookmarks
        var uniqueDomains = Set<String>()
        
        for bookmark in bookmarks {
            // Extract domain from the account's url or the status url
            if let accountDomain = extractDomain(from: bookmark.account.url) {
                uniqueDomains.insert(accountDomain)
            }
            
            // Also check for domains in mentions
            if let mentions = bookmark.mentions {
                for mention in mentions {
                    if let mentionDomain = extractDomain(from: mention.url) {
                        uniqueDomains.insert(mentionDomain)
                    }
                }
            }
            
            // Check for reblog domains
            if let reblog = bookmark.reblog {
                if let reblogDomain = extractDomain(from: reblog.account.url) {
                    uniqueDomains.insert(reblogDomain)
                }
            }
        }
        
        print("🌐 Found \(uniqueDomains.count) unique domains in bookmarks: \(uniqueDomains)")
        
        // Fetch emoji for each unique domain
        for domain in uniqueDomains {
            if emojiViewModel.isCacheStale(for: domain) {
                print("🔄 Fetching emoji for domain: \(domain)")
                emojiViewModel.fetchCustomEmoji(for: domain)
            } else {
                print("✅ Using cached emoji for domain: \(domain)")
            }
        }
    }

    // Helper function to extract domain from URL
    private func extractDomain(from urlString: String?) -> String? {
        guard let urlString = urlString,
              let url = URL(string: urlString),
              let host = url.host else {
            return nil
        }
        return host
    }
    
    private func debugDecodeBookmarks(from data: Data) {
        do {
            // Try to decode as Dictionary first to see the structure
            if let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                if let firstItem = json.first {
                    print("✅ JSON structure valid. First item keys: \(Array(firstItem.keys))")
                } else {
                    print("✅ JSON structure valid, but it’s an empty array.")
                }
                
                // Check specific fields we need
                if let firstItem = json.first {
                    print("ID exists: \(firstItem["id"] != nil)")
                    print("Content exists: \(firstItem["content"] != nil)")
                    print("Account exists: \(firstItem["account"] != nil)")
                    print("Media_attachments exists: \(firstItem["media_attachments"] != nil)")
                    print("Mentions exists: \(firstItem["mentions"] != nil)")
                    print("Reblog exists: \(firstItem["reblog"] != nil)")
                    
                    // Check account structure if it exists
                    if let account = firstItem["account"] as? [String: Any] {
                        print("Account keys: \(Array(account.keys))")
                        print("URL exists in account: \(account["url"] != nil)")
                    }
                }
            }
        } catch {
            print("❌ Failed to parse JSON: \(error)")
        }
    }
}
