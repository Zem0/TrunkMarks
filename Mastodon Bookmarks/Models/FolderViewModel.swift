//
//  FolderViewModel.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 13/04/2025.
//

import Foundation

class FolderViewModel: ObservableObject {
    @Published var folders: [Folder] = []
    private let foldersKey = "savedFolders"
    
    init() {
        loadFolders()
    }
    
    // MARK: - Persistence
    
    private func loadFolders() {
        if let data = UserDefaults.standard.data(forKey: foldersKey) {
            do {
                let decoder = JSONDecoder()
                let folders = try decoder.decode([Folder].self, from: data)
                self.folders = folders
                print("✅ Loaded \(folders.count) folders from storage")
            } catch {
                print("❌ Failed to load folders: \(error.localizedDescription)")
            }
        }
    }
    
    private func saveFolders() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(folders)
            UserDefaults.standard.set(data, forKey: foldersKey)
            print("✅ Saved \(folders.count) folders to storage")
        } catch {
            print("❌ Failed to save folders: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Folder Management
    
    func createFolder(name: String) {
        let newFolder = Folder(name: name)
        folders.append(newFolder)
        saveFolders()
    }
    
    func deleteFolder(at indexSet: IndexSet) {
        folders.remove(atOffsets: indexSet)
        saveFolders()
    }
    
    func renameFolder(folder: Folder, newName: String) {
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[index].name = newName
            saveFolders()
        }
    }
    
    // MARK: - Bookmark Management
    
    func addBookmarkToFolder(folderId: UUID, bookmarkId: String) {
        if let index = folders.firstIndex(where: { $0.id == folderId }) {
            if !folders[index].bookmarkIds.contains(bookmarkId) {
                folders[index].bookmarkIds.append(bookmarkId)
                saveFolders()
            }
        }
    }
    
    func removeBookmarkFromFolder(folderId: UUID, bookmarkId: String) {
        if let index = folders.firstIndex(where: { $0.id == folderId }) {
            folders[index].bookmarkIds.removeAll(where: { $0 == bookmarkId })
            saveFolders()
        }
    }
    
    func getBookmarksForFolder(folder: Folder, allBookmarks: [Status]) -> [Status] {
        return allBookmarks.filter { status in
            folder.bookmarkIds.contains(status.id)
        }
    }
    
    func isFolderEmpty(folder: Folder) -> Bool {
        return folder.bookmarkIds.isEmpty
    }
    
    func isBookmarkInFolder(folderId: UUID, bookmarkId: String) -> Bool {
        guard let folder = folders.first(where: { $0.id == folderId }) else {
            return false
        }
        return folder.bookmarkIds.contains(bookmarkId)
    }
}
