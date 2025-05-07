//
//  RoundedCornerShape.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 22/04/2025.
//

import SwiftUI

struct RoundedCornerShape: Shape {
    var radius: CGFloat = 12
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
