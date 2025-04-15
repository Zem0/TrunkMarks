//
//  MainTabView.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 13/04/2025.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var bookmarksViewModel = BookmarksViewModel()
    @StateObject private var emojiViewModel = EmojiViewModel()
    @StateObject private var folderViewModel = FolderViewModel()
    @StateObject private var authViewModel: AuthViewModel
    
    init() {
        let bookmarksVM = BookmarksViewModel()
        let emojiVM = EmojiViewModel()
        _bookmarksViewModel = StateObject(wrappedValue: bookmarksVM)
        _emojiViewModel = StateObject(wrappedValue: emojiVM)
        _folderViewModel = StateObject(wrappedValue: FolderViewModel())
        _authViewModel = StateObject(wrappedValue: AuthViewModel(bookmarksViewModel: bookmarksVM, emojiViewModel: emojiVM))
    }
    
    var body: some View {
        if authViewModel.isAuthenticated {
            TabView {
                // Bookmarks Tab
                NavigationView {
                    BookmarksView(
                        bookmarksViewModel: bookmarksViewModel,
                        instanceURL: authViewModel.instanceURL,
                        accessToken: authViewModel.accessToken ?? "",
                        emojiViewModel: emojiViewModel
                    )
                    .environmentObject(folderViewModel)
                }
                .environmentObject(folderViewModel)
                .tabItem {
                    Label("Bookmarks", systemImage: "bookmark.fill")
                        .fontDesign(.rounded)
                }
                
                // Folders Tab
                NavigationView {
                    FolderListView(
                        folderViewModel: folderViewModel,
                        bookmarksViewModel: bookmarksViewModel,
                        emojiViewModel: emojiViewModel,
                        instanceDomain: authViewModel.instanceDomain
                    )
                    .environmentObject(folderViewModel)
                }
                .environmentObject(folderViewModel)
                .tabItem {
                    Label("Folders", systemImage: "folder.fill")
                }
            }
        } else {
            ConnectView(authVM: authViewModel)
        }
    }
}
