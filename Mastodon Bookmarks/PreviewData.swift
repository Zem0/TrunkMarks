//
//  Preview+Models.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 13/04/2025.
//

import Foundation
import SwiftUI

struct PreviewData {
    static var sampleAccount: Account {
        Account(
            username: "username",
            display_name: "Display Name",
            avatar: "PreviewAvatar",
            acct: "username",
            url: "https://mastodon.social/@username"
        )
    }
    
    static var sampleMediaAttachment: MediaAttachment {
        MediaAttachment(
            id: "1",
            type: "image",
            url: "PreviewMedia",
            preview_url: "PreviewMedia"
        )
    }
    
    static var sampleMention: Mention {
        Mention(
            id: "mention1",
            username: "mentioned_user",
            url: "https://mastodon.social/@mentioned_user",
            acct: "mentioned_user"
        )
    }
    
    static func createSampleStatus(id: String, content: String, withMedia: Bool = false) -> Status {
        let container = try! JSONSerialization.data(withJSONObject: [
            "id": id,
            "content": content,
            "account": [
                "username": "username",
                "display_name": "Display Name",
                "avatar": "PreviewAvatar",
                "acct": "username",
                "url": "https://mastodon.social/@username"
            ],
            "media_attachments": withMedia ? [
                [
                    "id": "1",
                    "type": "image",
                    "url": "PreviewMedia",
                    "preview_url": "PreviewMedia"
                ]
            ] : [],
            "mentions": [],
            "reblog": nil
        ])
        
        return try! JSONDecoder().decode(Status.self, from: container)
    }
    
    static var sampleStatus: Status {
        createSampleStatus(
            id: "123456",
            content: "<p>This is a sample post with <a href='https://mastodon.social'>a link</a> and <strong>bold text</strong>.</p><p>It even has multiple paragraphs to test spacing!</p>",
            withMedia: true
        )
    }
    
    static var sampleStatuses: [Status] {
        [
            sampleStatus,
            createSampleStatus(
                id: "234567",
                content: "<p>A <em>short</em> post.</p>"
            ),
            createSampleStatus(
                id: "345678",
                content: "<p>A third post with a very long text that should truncate in list view. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam in dui mauris. Vivamus hendrerit arcu sed erat molestie vehicula. Sed auctor neque eu tellus rhoncus ut eleifend nibh porttitor.</p>"
            )
        ]
    }
    
    static var sampleFolder: Folder {
        Folder(name: "Favorite Posts")
    }
    
    static var sampleFolders: [Folder] {
        [
            Folder(name: "Favorite Posts"),
            Folder(name: "Read Later"),
            Folder(name: "Inspiration")
        ]
    }
}
