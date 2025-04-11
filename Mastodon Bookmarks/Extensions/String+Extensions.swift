//
//  String+Extensions.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 06/04/2025.
//

import Foundation

extension String {
    func stripHTML() -> String {
        // Very basic HTML stripping
        // For a production app, consider using NSAttributedString or a more robust HTML parser
        let stripped = self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
        
        return stripped
    }
}
