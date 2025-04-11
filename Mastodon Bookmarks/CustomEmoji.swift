//
//  CustomEmoji.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 09/04/2025.
//

import Foundation

struct CustomEmoji: Codable, Identifiable, Hashable {
    var id: String { shortcode }
    let shortcode: String
    let url: String
    let staticUrl: String?
    let visibleInPicker: Bool?
    
    enum CodingKeys: String, CodingKey {
        case shortcode
        case url
        case staticUrl = "static_url"
        case visibleInPicker = "visible_in_picker"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(shortcode)
        hasher.combine(url)
    }
    
    static func == (lhs: CustomEmoji, rhs: CustomEmoji) -> Bool {
        return lhs.shortcode == rhs.shortcode && lhs.url == rhs.url
    }
}
