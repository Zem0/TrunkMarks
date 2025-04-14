//
//  FolderListView.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 13/04/2025.
//

import SwiftUI

struct FolderListView: View {
    @ObservedObject var folderViewModel: FolderViewModel
    @ObservedObject var bookmarksViewModel: BookmarksViewModel
    @ObservedObject var emojiViewModel: EmojiViewModel
    let instanceDomain: String
    @State private var showingNewFolderSheet = false
    @State private var newFolderName = ""
    
    var body: some View {
        VStack {
            if folderViewModel.folders.isEmpty {
                // Empty state
                VStack(spacing: 10) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No Folders")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("Use folders to organize your bookmarks")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showingNewFolderSheet = true
                    }) {
                        Text("Create Folder")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                }
                .padding()
            } else {
                // Folder list using ScrollView
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(folderViewModel.folders.enumerated()), id: \.element.id) { index, folder in
                            let bookmarksInFolder = folderViewModel.getBookmarksForFolder(folder: folder, allBookmarks: bookmarksViewModel.bookmarks)
                            
                            NavigationLink(destination: FolderDetailView(
                                folder: folder,
                                bookmarks: bookmarksInFolder,
                                instanceDomain: instanceDomain,
                                folderViewModel: folderViewModel,
                                emojiViewModel: emojiViewModel
                            )) {
                                HStack(spacing: 12) {
                                    // Folder icon
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.blue.opacity(0.1))
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.blue.opacity(0.6), lineWidth: 1)
                                                    .shadow(color: Color(.blue.opacity(0.7)),radius: 1, x: 0, y: 1)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                            )
                                        
                                        Image(systemName: "folder.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.blue)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(folder.name)
                                            .font(.headline)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Text("\(bookmarksInFolder.count) bookmark\(bookmarksInFolder.count == 1 ? "" : "s")")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Color(UIColor.systemBackground))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Add divider after each item except the last
                            if index < folderViewModel.folders.count - 1 {
                                Divider()
                                    .padding(.leading, 78) // Align with content after icon
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Folders")
        .toolbar {
            if !folderViewModel.folders.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewFolderSheet = true
                    }) {
                        Image(systemName: "folder.badge.plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewFolderSheet) {
            NavigationView {
                VStack {
                    TextField("Folder Name", text: $newFolderName)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("New Folder")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            newFolderName = ""
                            showingNewFolderSheet = false
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Create") {
                            if !newFolderName.isEmpty {
                                folderViewModel.createFolder(name: newFolderName)
                                newFolderName = ""
                                showingNewFolderSheet = false
                            }
                        }
                        .disabled(newFolderName.isEmpty)
                    }
                }
            }
        }
    }
}
