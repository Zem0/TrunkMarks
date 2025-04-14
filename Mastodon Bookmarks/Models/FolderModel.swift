//
//  FolderModel.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 13/04/2025.
//

import Foundation

struct Folder: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    var bookmarkIds: [String] = [] // Status IDs of bookmarks in this folder
    var createdAt: Date = Date()
    
    static func == (lhs: Folder, rhs: Folder) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
