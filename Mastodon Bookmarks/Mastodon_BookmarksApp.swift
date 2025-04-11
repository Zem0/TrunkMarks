//
//  Mastodon_BookmarksApp.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 06/04/2025.
//

import SwiftUI

@main
struct MastodonBookmarksApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @StateObject private var bookmarksViewModel = BookmarksViewModel()
    @StateObject private var emojiViewModel = EmojiViewModel()
    @StateObject private var imageCache = ImageCache()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.font, .system(.body, design: .rounded))
                .environmentObject(bookmarksViewModel).environmentObject(bookmarksViewModel)
                .environmentObject(emojiViewModel)
                .environmentObject(imageCache)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("📲 AppDelegate: App opened with URL: \(url)")
        return true
    }
}
