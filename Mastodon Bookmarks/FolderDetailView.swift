//
//  FolderDetailView.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 13/04/2025.
//

import SwiftUI

struct FolderDetailView: View {
    let folder: Folder
    let bookmarks: [Status]
    let instanceDomain: String
    @ObservedObject var folderViewModel: FolderViewModel
    @ObservedObject var emojiViewModel: EmojiViewModel
    @State private var isEditing = false
    @State private var folderName: String
    
    init(folder: Folder, bookmarks: [Status], instanceDomain: String, folderViewModel: FolderViewModel, emojiViewModel: EmojiViewModel) {
        self.folder = folder
        self.bookmarks = bookmarks
        self.instanceDomain = instanceDomain
        self.folderViewModel = folderViewModel
        self.emojiViewModel = emojiViewModel
        self._folderName = State(initialValue: folder.name)
    }
    
    var body: some View {
        VStack {
            if bookmarks.isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    Image(systemName: "bookmark.slash")
                        .font(.system(size: 70))
                        .foregroundColor(.gray)
                    
                    Text("No Bookmarks")
                        .font(.title2)
                    
                    Text("This folder is empty. Add bookmarks to this folder from the Bookmarks tab.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding()
            } else {
                // Bookmark list
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(bookmarks.enumerated()), id: \.element.id) { index, status in
                            VStack(spacing: 0) {
                                NavigationLink(destination: BookmarkDetailView(
                                    status: status,
                                    instanceDomain: instanceDomain,
                                    emojiViewModel: emojiViewModel
                                )
                                .environmentObject(folderViewModel)) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        // Account info
                                        HStack {
                                            AsyncImage(url: URL(string: status.account.avatar)) { phase in
                                                switch phase {
                                                case .empty:
                                                    ProgressView()
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                case .failure:
                                                    Image(systemName: "person.circle.fill")
                                                        .foregroundColor(.gray)
                                                @unknown default:
                                                    Image(systemName: "person.circle.fill")
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                            
                                            Text(status.account.display_name)
                                                .font(.headline)
                                        }
                                        .padding(.bottom, 4)
                                        
                                        // Content
                                        Text(status.content.stripHTML())
                                            .font(.body)
                                            .lineLimit(3)
                                            .lineSpacing(5)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        if !status.media_attachments.isEmpty {
                                            HStack {
                                                Image(systemName: "photo")
                                                Text("\(status.media_attachments.count) media attachment\(status.media_attachments.count > 1 ? "s" : "")")
                                            }
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button(role: .destructive, action: {
                                        folderViewModel.removeBookmarkFromFolder(folderId: folder.id, bookmarkId: status.id)
                                    }) {
                                        Label("Remove from Folder", systemImage: "minus.circle")
                                    }
                                }
                                
                                // Add divider after each item except the last
                                if index < bookmarks.count - 1 {
                                    Divider()
                                        .padding(.leading, 16)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(isEditing ? "" : folder.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing {
                    Button("Done") {
                        // Save edited name
                        folderViewModel.renameFolder(folder: folder, newName: folderName)
                        isEditing = false
                    }
                } else {
                    Menu {
                        Button(action: {
                            isEditing = true
                        }) {
                            Label("Rename Folder", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: {
                            // Find index and delete folder
                            if let index = folderViewModel.folders.firstIndex(where: { $0.id == folder.id }) {
                                folderViewModel.deleteFolder(at: IndexSet(integer: index))
                                // Navigate back
                            }
                        }) {
                            Label("Delete Folder", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            
            if isEditing {
                ToolbarItem(placement: .principal) {
                    TextField("Folder Name", text: $folderName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 200)
                }
            }
        }
    }
}
