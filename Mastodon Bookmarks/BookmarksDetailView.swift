//
//  BookmarksDetailView.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 07/04/2025.
//

import SwiftUI
import WebKit

struct BookmarkDetailView: View {
    let status: Status
    let instanceDomain: String
    @ObservedObject var emojiViewModel: EmojiViewModel
    @EnvironmentObject var folderViewModel: FolderViewModel
    @State private var showingFolderSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HTMLToSwiftUIView(htmlContent: status.content, lineLimit: nil)
                    .padding(.top, 8)
                    .padding(.horizontal)
                    .fontDesign(.rounded)
                
                // Display media attachments (images)
                if !status.media_attachments.filter({ $0.type == "image" }).isEmpty {
                    GeometryReader { geometry in
                        let width = geometry.size.width - 32 // horizontal padding
                        let height = width * 4 / 3            // dynamic height

                        if !status.media_attachments.filter({ $0.type == "image" }).isEmpty {
                            TabView {
                                ForEach(status.media_attachments.filter { $0.type == "image" }, id: \.id) { media in
                                    if let url = URL(string: media.url) {
                                        VStack {
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .empty:
                                                    ProgressView()
                                                        .frame(width: width, height: height)
                                                case .success(let image):
                                                    ZStack {
                                                        image
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: width)
                                                            .clipped()
                                                            .cornerRadius(12)
                                                            .blur(radius: 15)
                                                            .opacity(0.3)
                                                            .offset(y: 15)

                                                        image
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: width)
                                                            .cornerRadius(12)
                                                            .overlay(
                                                                RoundedRectangle(cornerRadius: 12)
                                                                    .strokeBorder(
                                                                        LinearGradient(
                                                                            colors: [.white, .black.opacity(1)],
                                                                            startPoint: .top,
                                                                            endPoint: .bottom
                                                                        ),
                                                                        lineWidth: 1.5
                                                                    )
                                                                    .blendMode(.overlay)
                                                                    .opacity(0.25)
                                                            )
                                                            .shadow(
                                                                color: Color.black.opacity(0.15),
                                                                radius: 6,
                                                                x: 0,
                                                                y: 5
                                                            )
                                                    }
                                                case .failure:
                                                    if media.url.contains("PreviewMedia") {
                                                        Image("PreviewMedia")
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fit)
                                                            .cornerRadius(12)
                                                            .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 5)
                                                            .padding(.horizontal, 16)
                                                    } else {
                                                        Image(systemName: "photo")
                                                            .font(.system(size: 50))
                                                            .frame(height: 200)
                                                            .frame(maxWidth: .infinity)
                                                            .background(Color.gray.opacity(0.2))
                                                            .cornerRadius(12)
                                                            .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 5)
                                                            .padding(.horizontal, 16)
                                                    }
                                                @unknown default:
                                                    EmptyView()
                                                }
                                            }
                                            Spacer() // pushes content to the top
                                        }
                                        .frame(width: geometry.size.width, height: height, alignment: .top)
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            .frame(height: height)
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                        }
                    }
                    .frame(height: UIScreen.main.bounds.width * 4 / 3) // ensures container reserves space
                }
                
                // Link to the post on Mastodon
                if let url = URL(string: "https://\(instanceDomain)/@\(status.account.username)/\(status.id)") {
                    Link("View on Mastodon", destination: url)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.blue)
                        .padding(.top)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    // Avatar
                    AsyncImage(url: URL(string: status.account.avatar)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            // For previews, check if it's an asset name rather than a URL
                            if status.account.avatar.contains("PreviewAvatar") {
                                Image(status.account.avatar)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                Image(systemName: "person.circle.fill")
                            }
                        @unknown default:
                            Image(systemName: "person.circle.fill")
                        }
                    }
                    .frame(width: 30, height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                            .shadow(color: Color(.black.opacity(0.6)),radius: 0.7, x: 0, y: 0.7)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    )
                    
                    // Display name
                    Text(status.account.display_name)
                        .font(.system(.headline, design: .rounded))
                }
            }
            
            // Add folder button
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingFolderSheet = true
                }) {
                    Image(systemName: "folder.badge.plus")
                }
            }
        }
        .onAppear {
            // Fetch emoji data for the current instance domain if the cache is stale
            if emojiViewModel.isCacheStale(for: instanceDomain) {
                emojiViewModel.fetchCustomEmoji(for: instanceDomain)
            }
        }
        .sheet(isPresented: $showingFolderSheet) {
            NavigationView {
                VStack {
                    if folderViewModel.folders.isEmpty {
                        // Empty state
                        VStack(spacing: 20) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 70))
                                .foregroundColor(.gray)
                            
                            Text("No Folders")
                                .font(.title2)
                            
                            Text("Create a folder to organize your bookmarks")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            Button(action: {
                                // This adds a new folder and assigns the current bookmark to it
                                let newFolderName = "New Folder"
                                folderViewModel.createFolder(name: newFolderName)
                                if let newFolder = folderViewModel.folders.last {
                                    folderViewModel.addBookmarkToFolder(folderId: newFolder.id, bookmarkId: status.id)
                                }
                                showingFolderSheet = false
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
                        List {
                            ForEach(folderViewModel.folders) { folder in
                                let isInFolder = folderViewModel.isBookmarkInFolder(folderId: folder.id, bookmarkId: status.id)
                                
                                Button(action: {
                                    if isInFolder {
                                        folderViewModel.removeBookmarkFromFolder(folderId: folder.id, bookmarkId: status.id)
                                    } else {
                                        folderViewModel.addBookmarkToFolder(folderId: folder.id, bookmarkId: status.id)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "folder.fill")
                                            .foregroundColor(.blue)
                                        
                                        Text(folder.name)
                                        
                                        Spacer()
                                        
                                        if isInFolder {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                            
                            Button(action: {
                                // Create a new folder
                                let newFolderName = "New Folder \(folderViewModel.folders.count + 1)"
                                folderViewModel.createFolder(name: newFolderName)
                                // Select the last created folder
                                if let newFolder = folderViewModel.folders.last {
                                    folderViewModel.addBookmarkToFolder(folderId: newFolder.id, bookmarkId: status.id)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "folder.badge.plus")
                                        .foregroundColor(.blue)
                                    Text("Create New Folder")
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Add to Folder")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingFolderSheet = false
                        }
                    }
                }
            }
        }
    }
}

struct BookmarkDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BookmarkDetailView(
                status: PreviewData.sampleStatus,
                instanceDomain: "mastodon.social",
                emojiViewModel: EmojiViewModel()
            )
            .environmentObject(FolderViewModel())
        }
    }
}
