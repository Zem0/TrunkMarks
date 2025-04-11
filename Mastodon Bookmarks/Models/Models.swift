//
//  Models.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 06/04/2025.
//

import Foundation

class Status: Codable, Identifiable {
    let id: String
    let content: String
    let account: Account
    let media_attachments: [MediaAttachment]
    let mentions: [Mention]?
    let reblog: Status?
    
    enum CodingKeys: String, CodingKey {
        case id, content, account, media_attachments, mentions, reblog
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        id = try container.decode(String.self, forKey: .id)
        
        // Fields that might fail - provide fallbacks
        do {
            content = try container.decode(String.self, forKey: .content)
        } catch {
            print("⚠️ Failed to decode content: \(error)")
            content = "" // Fallback to empty string
        }
        
        do {
            account = try container.decode(Account.self, forKey: .account)
        } catch {
            print("⚠️ Failed to decode account: \(error)")
            throw error // This field is important so re-throw
        }
        
        do {
            media_attachments = try container.decode([MediaAttachment].self, forKey: .media_attachments)
        } catch {
            print("⚠️ Failed to decode media_attachments: \(error)")
            media_attachments = [] // Fallback to empty array
        }
        
        // Optional fields
        mentions = try? container.decodeIfPresent([Mention].self, forKey: .mentions)
        reblog = try? container.decodeIfPresent(Status.self, forKey: .reblog)
    }
}

struct Account: Codable, Equatable, Hashable {
    let username: String
    let display_name: String
    let avatar: String
    let acct: String       // Changed from "account" to "acct"
    let url: String
    
    // Add hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(username)
    }
    
    // Add equatable conformance
    static func == (lhs: Account, rhs: Account) -> Bool {
        return lhs.username == rhs.username
    }
}

struct Mention: Codable {
    let id: String
    let username: String
    let url: String
    let acct: String
}

struct ClientCredentials: Codable {
    let client_id: String
    let client_secret: String
}

struct AccessTokenResponse: Codable {
    let access_token: String
}

struct MediaAttachment: Codable, Identifiable {
    let id: String
    let type: String // e.g., "image", "video", etc.
    let url: String
    let preview_url: String?
}
