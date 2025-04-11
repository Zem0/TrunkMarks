//
//  EmojiViewModel.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 09/04/2025.
//

import Foundation
import SwiftUI
import Combine

class EmojiViewModel: ObservableObject {
    @Published var emojiDicts: [String: [String: CustomEmoji]] = [:]
    @Published var isLoading: Bool = false
    @Published var lastUpdated: [String: Date] = [:]

    private var cancellables = Set<AnyCancellable>()
    
    // Keys for UserDefaults
    private func emojiCacheKey(for domain: String) -> String {
        "cachedCustomEmoji_\(domain)"
    }
    
    private func emojiCacheTimeKey(for domain: String) -> String {
        "cachedCustomEmojiTime_\(domain)"
    }
    
    init() {
        loadAllCachedEmoji()
    }

    // MARK: - Caching

    private func loadAllCachedEmoji() {
        // This could be expanded to load known domains from disk
        // For now, use a fixed list or load on demand
        let storedDomains = UserDefaults.standard.stringArray(forKey: "cachedEmojiDomains") ?? []
        for domain in storedDomains {
            loadCachedEmoji(for: domain)
        }
    }

    private func loadCachedEmoji(for domain: String) {
        let key = emojiCacheKey(for: domain)
        if let data = UserDefaults.standard.data(forKey: key),
           let cachedEmoji = try? JSONDecoder().decode([CustomEmoji].self, from: data) {
            
            let dict = Dictionary(uniqueKeysWithValues: cachedEmoji.map { ($0.shortcode, $0) })
            emojiDicts[domain] = dict
            
            if let cacheTime = UserDefaults.standard.object(forKey: emojiCacheTimeKey(for: domain)) as? Date {
                lastUpdated[domain] = cacheTime
            }
            
            print("✅ Loaded \(dict.count) cached emoji for \(domain)")
        }
    }

    private func saveEmojiToCache(emoji: [CustomEmoji], for domain: String) {
        do {
            // Create a dictionary that handles duplicates by keeping only the first occurrence
            var uniqueEmojis: [CustomEmoji] = []
            var seenShortcodes = Set<String>()
            
            for currentEmoji in emoji {
                if !seenShortcodes.contains(currentEmoji.shortcode) {
                    uniqueEmojis.append(currentEmoji)
                    seenShortcodes.insert(currentEmoji.shortcode)
                }
            }
            
            // Save the unique list
            let data = try JSONEncoder().encode(uniqueEmojis)
            UserDefaults.standard.set(data, forKey: emojiCacheKey(for: domain))
            let now = Date()
            UserDefaults.standard.set(now, forKey: emojiCacheTimeKey(for: domain))
            lastUpdated[domain] = now

            // Track known domains
            var knownDomains = UserDefaults.standard.stringArray(forKey: "cachedEmojiDomains") ?? []
            if !knownDomains.contains(domain) {
                knownDomains.append(domain)
                UserDefaults.standard.set(knownDomains, forKey: "cachedEmojiDomains")
            }

            print("✅ Cached \(uniqueEmojis.count) emoji for \(domain)")
        } catch {
            print("❌ Failed to cache emoji for \(domain): \(error.localizedDescription)")
        }
    }

    // MARK: - Fetching

    func fetchCustomEmoji(for domain: String) {
        
        // Skip empty or placeholder domains
        if domain.isEmpty || domain == "your-default-instance.com" {
            print("⚠️ Skipping invalid domain: \(domain)")
            return
        }

        // Remove any protocol prefix if present
        var cleanDomain = domain
        if cleanDomain.hasPrefix("https://") {
            cleanDomain = String(cleanDomain.dropFirst(8))
        } else if cleanDomain.hasPrefix("http://") {
            cleanDomain = String(cleanDomain.dropFirst(7))
        }
        
        guard let url = URL(string: "https://\(cleanDomain)/api/v1/custom_emojis") else {
            print("❌ Invalid URL for domain: \(domain)")
            return
        }
        
        isLoading = true
        print("📡 Fetching emoji from \(cleanDomain)")

        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [CustomEmoji].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    print("❌ Error fetching emoji from \(domain): \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] emoji in
                // Filter out duplicates before creating the dictionary
                var uniqueDict: [String: CustomEmoji] = [:]
                
                for currentEmoji in emoji {
                    // Only add if we don't already have this shortcode
                    if uniqueDict[currentEmoji.shortcode] == nil {
                        uniqueDict[currentEmoji.shortcode] = currentEmoji
                    }
                }
                
                self?.emojiDicts[domain] = uniqueDict
                self?.saveEmojiToCache(emoji: emoji, for: domain)
                print("✅ Fetched \(emoji.count) emoji from \(domain)")
            })
            .store(in: &cancellables)
    }

    // MARK: - Staleness Check

    func isCacheStale(for domain: String) -> Bool {
        guard let lastUpdated = lastUpdated[domain] else {
            return true
        }

        let calendar = Calendar.current
        if let dayDifference = calendar.dateComponents([.day], from: lastUpdated, to: Date()).day,
           dayDifference >= 1 {
            return true
        }

        return false
    }
}
