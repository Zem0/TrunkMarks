//
//  AttributedHTMLText.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 23/04/2025.
//

import SwiftUI
import UIKit

struct AttributedHTMLText: UIViewRepresentable {
    private let htmlContent: String
    private let lineLimit: Int?
    private let font: UIFont
    private let textColor: UIColor
    private let linkColor: UIColor
    
    init(
        htmlContent: String,
        lineLimit: Int? = nil,
        font: UIFont = .systemFont(ofSize: 17, weight: .regular),
        textColor: UIColor = .label,
        linkColor: UIColor = UIColor(red: 0.11, green: 0.61, blue: 0.94, alpha: 1.0) // #1D9BF0
    ) {
        self.htmlContent = htmlContent
        self.lineLimit = lineLimit
        self.font = font
        self.textColor = textColor
        self.linkColor = linkColor
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        
        // Configure the text view appearance
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        
        // These settings are crucial for correct height calculation
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.required, for: .vertical)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        textView.attributedText = processHTML(html: htmlContent)
        
        // Apply line limit if specified
        if let lineLimit = lineLimit {
            textView.textContainer.maximumNumberOfLines = lineLimit
            textView.textContainer.lineBreakMode = .byTruncatingTail
        } else {
            textView.textContainer.maximumNumberOfLines = 0
        }
        
        // Force layout calculation immediately
        textView.setNeedsLayout()
        textView.layoutIfNeeded()
    }
    
    @available(iOS 16.0, *)
    func sizeThatFits(_ proposal: ProposedViewSize, uiView textView: UITextView, context: Context) -> CGSize? {
        // This is critical for correctly sizing rows in a List
        if let width = proposal.width, width != .infinity {
            let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
            let boundingBox = textView.sizeThatFits(constraintRect)
            return CGSize(width: width, height: boundingBox.height)
        }
        return nil
    }
    
    private func processHTML(html: String) -> NSAttributedString {
        // Clean up the HTML and add basic styling
        let processedHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system;
                    font-size: \(font.pointSize)px;
                    line-height: 1.4;
                    color: \(hexString(from: textColor));
                    margin: 0;
                    padding: 0;
                }
                a {
                    color: \(hexString(from: linkColor));
                    text-decoration: none;
                }
                p {
                    margin-top: 0;
                    margin-bottom: 4px;
                }
            </style>
        </head>
        <body>
            \(html)
        </body>
        </html>
        """
        
        // Default fallback
        let defaultString = NSAttributedString(string: html.stripHTML())
        
        guard let data = processedHTML.data(using: .utf8) else {
            return defaultString
        }
        
        do {
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            
            return try NSAttributedString(data: data, options: options, documentAttributes: nil)
        } catch {
            print("Error converting HTML: \(error)")
            return defaultString
        }
    }
    
    // Helper function to convert UIColor to hex string for CSS
    private func hexString(from color: UIColor) -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return String(
            format: "#%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
    }
}

// Assuming you have this extension already
//extension String {
//    func stripHTML() -> String {
//        // Your existing HTML stripping implementation
//        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
//    }
//}
