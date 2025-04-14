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
    
    init() {
        // Create standard appearance
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        
        // Create transparent appearance for scroll edge (when at top)
        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground()
        
        // Apply font styling to both appearances
        if let roundedDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
            .withDesign(.rounded) {
            
            let weightedDescriptor = roundedDescriptor.addingAttributes([
                UIFontDescriptor.AttributeName.traits: [
                    UIFontDescriptor.TraitKey.weight: UIFont.Weight.semibold
                ]
            ])
            
            let titleFont = UIFont(descriptor: weightedDescriptor, size: 17)
            standardAppearance.titleTextAttributes = [NSAttributedString.Key.font: titleFont]
            scrollEdgeAppearance.titleTextAttributes = [NSAttributedString.Key.font: titleFont]
        }
        
        // Apply font styling for large titles
        if let largeTitleDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle)
            .withDesign(.rounded) {
            
            let weightedLargeDescriptor = largeTitleDescriptor.addingAttributes([
                UIFontDescriptor.AttributeName.traits: [
                    UIFontDescriptor.TraitKey.weight: UIFont.Weight.bold
                ]
            ])
            
            let largeTitleFont = UIFont(descriptor: weightedLargeDescriptor, size: 34)
            standardAppearance.largeTitleTextAttributes = [NSAttributedString.Key.font: largeTitleFont]
            scrollEdgeAppearance.largeTitleTextAttributes = [NSAttributedString.Key.font: largeTitleFont]
        }
        
        // Apply the different appearances to the navigation bar
        UINavigationBar.appearance().standardAppearance = standardAppearance
        UINavigationBar.appearance().compactAppearance = standardAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = scrollEdgeAppearance
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
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
