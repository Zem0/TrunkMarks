//
//  AuthViewModel.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 06/04/2025.
//

import Foundation
import UIKit
import Combine

class AuthViewModel: ObservableObject {
    @Published var instanceDomain: String = ""
    @Published var accessToken: String? = nil
    @Published var isAuthenticated: Bool = false // Added to explicitly track authentication state
    var clientId: String = ""
    var clientSecret: String = ""
    var emojiViewModel: EmojiViewModel
    
    // Reference to the BookmarksViewModel to handle bookmarks management
    var bookmarksViewModel: BookmarksViewModel

    var instanceURL: String {
        "https://\(instanceDomain)"
    }
    
    // Initialize and load access token and instance domain from UserDefaults
    init(bookmarksViewModel: BookmarksViewModel, emojiViewModel: EmojiViewModel) {
        self.bookmarksViewModel = bookmarksViewModel
        self.emojiViewModel = emojiViewModel
        
        // Set the emoji view model reference in bookmarks view model
        bookmarksViewModel.setEmojiViewModel(emojiViewModel)
        
        loadInstanceDomain() // Load the saved instance domain
        loadAccessToken()    // Load the saved access token
        
        // Set the authentication state based on loaded values
        self.isAuthenticated = accessToken != nil && !instanceDomain.isEmpty
        
        // If we're authenticated, fetch custom emoji
        if self.isAuthenticated {
            emojiViewModel.fetchCustomEmoji(for: instanceURL)
        }
    }
    
    // Save the access token to UserDefaults
    func saveAccessToken(token: String) {
        print("✅ Saving access token to UserDefaults: \(token)")
        UserDefaults.standard.set(token, forKey: "accessToken")
    }
    
    // Save the instance domain to UserDefaults
    func saveInstanceDomain(domain: String) {
        print("✅ Saving instance domain to UserDefaults: \(domain)")
        UserDefaults.standard.set(domain, forKey: "instanceDomain")
        
        // Debug: Confirm if the domain is saved correctly
        let savedDomain = UserDefaults.standard.string(forKey: "instanceDomain")
        print("🔄 Instance domain saved to UserDefaults: \(savedDomain ?? "nil")")
    }
    
    // Load access token from UserDefaults
    func loadAccessToken() {
        if let token = UserDefaults.standard.string(forKey: "accessToken") {
            self.accessToken = token
            print("🔄 Loaded access token from UserDefaults: \(token)")
        } else {
            print("❌ No access token found in UserDefaults.")
        }
    }
    
    // Load instance domain from UserDefaults
    func loadInstanceDomain() {
        if let domain = UserDefaults.standard.string(forKey: "instanceDomain") {
            self.instanceDomain = domain
            print("🔄 Loaded instance domain from UserDefaults: \(domain)")
        } else {
            print("❌ No instance domain found in UserDefaults.")
        }
    }
    
    // Register the app
    func registerApp() {
        guard !instanceDomain.isEmpty else {
            print("⚠️ instanceDomain is empty!")
            return
        }

        let instanceURL = "https://\(instanceDomain)"
        print("📡 Registering app at: \(instanceURL)")

        let appRegistrationURL = URL(string: "\(instanceURL)/api/v1/apps")!
        let redirectURI = "mastodonbookmarks://callback"
        
        let params = [
            "client_name": "BookmarkBuddy",
            "redirect_uris": redirectURI,
            "scopes": "read",
            "website": "https://yourapp.website"
        ]

        var request = URLRequest(url: appRegistrationURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: params)

        print("📨 Sending app registration request to: \(appRegistrationURL)")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("❌ Network error: \(error)")
                return
            }

            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let clientId = json["client_id"] as? String,
                let clientSecret = json["client_secret"] as? String
            else {
                print("❌ Could not decode app registration response")
                if let data = data, let responseStr = String(data: data, encoding: .utf8) {
                    print("📄 Raw response: \(responseStr)")
                }
                return
            }
            // Store the credentials on the view model for later use
            self.clientId = clientId
            self.clientSecret = clientSecret

            print("🔐 Saved client ID and secret")

            print("✅ Registered app. Client ID: \(clientId)")

            let authURL = "\(instanceURL)/oauth/authorize?client_id=\(clientId)&redirect_uri=\(redirectURI)&response_type=code&scope=read"
            print("🌐 Opening auth URL: \(authURL)")

            DispatchQueue.main.async {
                guard let url = URL(string: authURL) else {
                    print("🚨 Invalid auth URL")
                    return
                }
                UIApplication.shared.open(url)
            }
        }.resume()
    }
    
    // Handle the callback URL
    func handleAuthCallback(url: URL) {
        print("📥 Received callback URL: \(url)")

        // Extract the authorization code from the URL
        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else {
            print("❌ Failed to extract code from callback URL")
            return
        }

        print("🔑 Authorization code received: \(code)")

        // Exchange the authorization code for an access token
        exchangeCodeForToken(code: code)
    }

    private func exchangeCodeForToken(code: String) {
        let redirectURI = "mastodonbookmarks://callback"
        let tokenURL = URL(string: "https://\(instanceDomain)/oauth/token")!

        let params = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI,
            "scope": "read"
        ]

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = params
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        print("📡 Exchanging code for token...")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Failed to retrieve access token: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("❌ No data received when retrieving access token")
                return
            }
            
            // Try to get detailed error info
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Token response: \(jsonString)")
            }
            
            guard
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let token = json["access_token"] as? String
            else {
                print("❌ Failed to parse access token response")
                return
            }

            DispatchQueue.main.async {
                self.accessToken = token
                self.saveAccessToken(token: token) // Save token to UserDefaults
                self.isAuthenticated = true // Set the authenticated state
                print("✅ Access token saved to UserDefaults and authenticated state updated")
                
                // Fetch bookmarks right away
                self.fetchBookmarks()
                
                // Also fetch custom emoji
                self.emojiViewModel.fetchCustomEmoji(for: self.instanceURL)
            }
        }.resume()
    }
    
    // Trigger bookmark fetch from BookmarksViewModel
    func fetchBookmarks() {
        guard let token = accessToken else {
            print("❌ No access token found.")
            return
        }

        // Call the loadBookmarks function from the BookmarksViewModel
        bookmarksViewModel.loadBookmarks(instanceURL: instanceURL, token: token)
    }
}
