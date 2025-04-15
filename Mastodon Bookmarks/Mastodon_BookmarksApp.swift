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
        // Configure navigation bar appearances
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        
        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground()
        
        // Apply rounded fonts to navigation bars
        if let roundedFont = UIFont.systemFont(ofSize: 17, weight: .semibold).withDesign(.rounded) {
            standardAppearance.titleTextAttributes = [.font: roundedFont]
            scrollEdgeAppearance.titleTextAttributes = [.font: roundedFont]
        }
        
        if let roundedLargeFont = UIFont.systemFont(ofSize: 34, weight: .bold).withDesign(.rounded) {
            standardAppearance.largeTitleTextAttributes = [.font: roundedLargeFont]
            scrollEdgeAppearance.largeTitleTextAttributes = [.font: roundedLargeFont]
        }
        
        // Apply rounded font to the back button
        if let backButtonFont = UIFont.systemFont(ofSize: 17, weight: .regular).withDesign(.rounded) {
            standardAppearance.backButtonAppearance.normal.titleTextAttributes = [.font: backButtonFont]
            scrollEdgeAppearance.backButtonAppearance.normal.titleTextAttributes = [.font: backButtonFont]
        }
        
        UINavigationBar.appearance().standardAppearance = standardAppearance
        UINavigationBar.appearance().compactAppearance = standardAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = scrollEdgeAppearance
        
        // Apply rounded font to all bar button items
        if let buttonFont = UIFont.systemFont(ofSize: 17).withDesign(.rounded) {
            UIBarButtonItem.appearance().setTitleTextAttributes([.font: buttonFont], for: .normal)
            UIBarButtonItem.appearance().setTitleTextAttributes([.font: buttonFont], for: .highlighted)
            
            // Specifically for back button items
            let backButtonAttributes: [NSAttributedString.Key: Any] = [.font: buttonFont]
            UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
                .setTitleTextAttributes(backButtonAttributes, for: .normal)
            UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
                .setTitleTextAttributes(backButtonAttributes, for: .highlighted)
        }
        
        // Apply rounded font to tab bar items
        if let tabBarFont = UIFont.systemFont(ofSize: 10, weight: .medium).withDesign(.rounded) {
            UITabBarItem.appearance().setTitleTextAttributes([.font: tabBarFont], for: .normal)
            UITabBarItem.appearance().setTitleTextAttributes([.font: tabBarFont], for: .selected)
            
            // Additionally, configure the tab bar appearance
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithDefaultBackground()
            tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.font: tabBarFont]
            tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.font: tabBarFont]
            
            UITabBar.appearance().standardAppearance = tabBarAppearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }
        }
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

extension UIFont {
    func withDesign(_ design: UIFontDescriptor.SystemDesign) -> UIFont? {
        guard let descriptor = self.fontDescriptor.withDesign(design) else {
            return nil
        }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("📲 AppDelegate: App opened with URL: \(url)")
        return true
    }
}
