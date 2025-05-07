//
//  HTMLToSwiftUIView.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 09/04/2025.
//

import SwiftUI

struct HTMLToSwiftUIView: View {
    let htmlContent: String
    let lineLimit: Int?
    @State private var attributedText: AttributedString = AttributedString("")
    @State private var isProcessing = false
    
    init(htmlContent: String, lineLimit: Int? = nil) {
        self.htmlContent = htmlContent
        self.lineLimit = lineLimit
    }
    
    var body: some View {
        Group {
            if attributedText.characters.count > 0 {
                Text(attributedText)
                    .font(.system(.body, design: .rounded))
                    .lineLimit(lineLimit)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true) // This is key for dynamic height
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("...")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(isProcessing ? 1 : 0)
            }
        }
//        .background(.red) // Keep for debugging
        .onAppear {
            // Only process HTML if needed
            if attributedText.characters.count == 0 && !isProcessing {
                isProcessing = true
                // Move processing to background thread
                DispatchQueue.global(qos: .userInitiated).async {
                    let processed = processHTML(html: htmlContent)
                    // Update UI on main thread
                    DispatchQueue.main.async {
                        self.attributedText = processed
                        self.isProcessing = false
                    }
                }
            }
        }
    }
    
    // Process HTML in a separate function for background thread
    private func processHTML(html: String) -> AttributedString {
        // First, parse the HTML to separate paragraphs and add spacing between them
        let htmlWithProperSpacing = processHTMLParagraphs(html)
        
        // Default result in case of error
        var result = AttributedString(html.stripHTML())
        
        // Convert HTML to NSAttributedString
        if let data = htmlWithProperSpacing.data(using: .utf8) {
            do {
                let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ]
                
                let attributedString = try NSAttributedString(data: data, options: options, documentAttributes: nil)
                result = AttributedString(attributedString)
                
                // Remove trailing whitespace/newlines if any
                if let lastNewline = result.characters.lastIndex(of: "\n") {
                    if lastNewline == result.characters.index(before: result.endIndex) {
                        result.removeSubrange(lastNewline...)
                    }
                }
                
            } catch {
                print("Error converting HTML: \(error)")
                // Fallback already set to stripped HTML
            }
        }
        
        return result
    }
    
    // Helper function to process HTML paragraphs and ensure correct spacing
    private func processHTMLParagraphs(_ html: String) -> String {
        // Create the wrapper HTML with styles
        let baseHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system;
                    font-size: 17px;
                    line-height: 1.5;
                    color: #000000;
                    margin: 0;
                    padding: 0;
                }
                a {
                    color: #1D9BF0;
                    text-decoration: none;
                }
                p {
                    margin: 0;
                    padding: 0;
                }
                .paragraph-spacer {
                    display: block;
                    height: 10px;
                    line-height: 10px;
                }
                @media (prefers-color-scheme: dark) {
                    body { color: #FFFFFF; }
                }
            </style>
        </head>
        <body>
        """
        
        // Extract paragraphs - we need to be careful to handle HTML correctly
        let paragraphs = html.components(separatedBy: "</p>")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            
        var processedContent = ""
        
        // Process paragraphs to add spacers between them but not after the last one
        for (index, paragraph) in paragraphs.enumerated() {
            // Add the paragraph
            let trimmedParagraph = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedParagraph.isEmpty {
                continue
            }
            
            // Make sure it has an opening tag if it doesn't already
            var fullParagraph = trimmedParagraph
            if !fullParagraph.lowercased().contains("<p") {
                fullParagraph = "<p>" + fullParagraph
            }
            
            // Add the closing tag
            fullParagraph += "</p>"
            
            processedContent += fullParagraph
            
            // Add spacer only between paragraphs, not after the last one
            if index < paragraphs.count - 1 {
                processedContent += "<div class='paragraph-spacer'></div>"
            }
        }
        
        // Close the HTML
        let fullHTML = baseHTML + processedContent + "</body></html>"
        return fullHTML
    }
}

// Helper extension for conditional modifiers
extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
