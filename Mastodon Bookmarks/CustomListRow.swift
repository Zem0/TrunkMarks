//
//  CustomListRow.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 12/04/2025.
//

import SwiftUI

struct CustomListRow<Content: View>: View {
    let content: Content
    let isFirstRow: Bool
    let showBottomSeparator: Bool
    
    init(isFirstRow: Bool = false, showBottomSeparator: Bool = true, @ViewBuilder content: () -> Content) {
        self.isFirstRow = isFirstRow
        self.showBottomSeparator = showBottomSeparator
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color(UIColor.systemBackground))
            
            if showBottomSeparator {
                Divider()
                    .padding(.leading, 16)
            }
        }
    }
}

struct CustomList<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                content
            }
        }
    }
}
