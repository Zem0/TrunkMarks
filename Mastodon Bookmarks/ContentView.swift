//
//  ContentView.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 06/04/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var bookmarksViewModel = BookmarksViewModel()
    @StateObject private var emojiViewModel = EmojiViewModel()
    @StateObject private var authViewModel: AuthViewModel
    
    init() {
        let bookmarksVM = BookmarksViewModel()
        let emojiVM = EmojiViewModel()
        _bookmarksViewModel = StateObject(wrappedValue: bookmarksVM)
        _emojiViewModel = StateObject(wrappedValue: emojiVM)
        _authViewModel = StateObject(wrappedValue: AuthViewModel(bookmarksViewModel: bookmarksVM, emojiViewModel: emojiVM))
    }

    var body: some View {
        NavigationView {
            VStack {
                if authViewModel.isAuthenticated {
                    BookmarksView(
                        bookmarksViewModel: bookmarksViewModel,
                        instanceURL: "https://" + authViewModel.instanceDomain, // Ensure URL has protocol
                        accessToken: authViewModel.accessToken ?? "",
                        emojiViewModel: emojiViewModel
                    )
                } else {
                    ConnectView(authVM: authViewModel)
                }
            }
        }
        .onOpenURL { url in
            // Handle deep link callback from Safari
            print("📲 App opened with URL: \(url)")
            authViewModel.handleAuthCallback(url: url)
        }
    }
}

struct ConnectView: View {
    @ObservedObject var authVM: AuthViewModel
    var body: some View {
        VStack(spacing: 16) {
            Text("Connect to Mastodon")
                .font(.title)

            TextField("Enter your instance (e.g. mastodon.social)", text: $authVM.instanceDomain)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(.horizontal)
                .onChange(of: authVM.instanceDomain) { newValue in
                    print("Updated instanceDomain: \(newValue)")  // Debugging: check input as user types
                }

            Button("Connect") {
                // Debugging: Print the instance domain entered by the user
                print("User entered instance domain: \(authVM.instanceDomain)")

                guard !authVM.instanceDomain.isEmpty else {
                    print("⚠️ Instance domain is empty!")
                    return
                }

                // Save the domain to UserDefaults before registering
                authVM.saveInstanceDomain(domain: authVM.instanceDomain)

                // Proceed to register the app with Mastodon
                authVM.registerApp()  // Correct method call without trailing closure
            }
            .disabled(authVM.instanceDomain.isEmpty)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
