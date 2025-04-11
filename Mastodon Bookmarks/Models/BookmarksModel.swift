//
//  BookmarksModel.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 06/04/2025.
//

import Foundation

struct Bookmark: Identifiable, Codable {
    let id: String
    let content: String
    let url: String
    let mediaURL: String?
    let username: String
    let avatarURL: String
    let postURL: String

    // You can also create an initializer if you'd like to make it easier to construct the model from the API response
    init(id: String, content: String, url: String, mediaURL: String? = nil, username: String, avatarURL: String, postURL: String) {
        self.id = id
        self.content = content
        self.url = url
        self.mediaURL = mediaURL
        self.username = username
        self.avatarURL = avatarURL
        self.postURL = postURL
    }
}
