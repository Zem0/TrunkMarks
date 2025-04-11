//
//  EmojiTextView.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 09/04/2025.
//

import SwiftUI

struct EmojiTextView: View {
    let text: String
    // Change to accept multiple emoji dictionaries mapped by server domain
    let emojiDicts: [String: [String: CustomEmoji]]
    // Default emoji dict for backward compatibility
    let defaultEmojiDict: [String: CustomEmoji]
    let fontSize: CGFloat?
    let lineLimit: Int?
    let textColor: Color?
    let fontWeight: Font.Weight?
    let fontDesign: Font.Design?
    let textStyle: Font.TextStyle?
    
    // Add a unique ID for this specific instance
    let viewID = UUID()
    
    init(
        text: String,
        emojiDict: [String: CustomEmoji],
        fontSize: CGFloat? = 16,
        lineLimit: Int? = nil,
        textColor: Color? = nil,
        fontWeight: Font.Weight? = nil,
        fontDesign: Font.Design? = nil,
        textStyle: Font.TextStyle? = nil
    ) {
        self.text = text
        self.defaultEmojiDict = emojiDict
        self.emojiDicts = [:] // Empty for backward compatibility
        self.fontSize = fontSize
        self.lineLimit = lineLimit
        self.textColor = textColor
        self.fontWeight = fontWeight
        self.fontDesign = fontDesign
        self.textStyle = textStyle
    }
    
    // New initializer for multiple server support
    init(
        text: String,
        emojiDicts: [String: [String: CustomEmoji]],
        defaultEmojiDict: [String: CustomEmoji] = [:],
        fontSize: CGFloat? = 16,
        lineLimit: Int? = nil,
        textColor: Color? = nil,
        fontWeight: Font.Weight? = nil,
        fontDesign: Font.Design? = nil,
        textStyle: Font.TextStyle? = nil
    ) {
        self.text = text
        self.emojiDicts = emojiDicts
        self.defaultEmojiDict = defaultEmojiDict
        self.fontSize = fontSize
        self.lineLimit = lineLimit
        self.textColor = textColor
        self.fontWeight = fontWeight
        self.fontDesign = fontDesign
        self.textStyle = textStyle
    }
    
    private var font: Font {
        if let textStyle = textStyle {
            if let fontDesign = fontDesign {
                var font = Font.system(textStyle, design: fontDesign)
                if let fontWeight = fontWeight {
                    font = font.weight(fontWeight)
                }
                return font
            } else {
                var font = Font.system(textStyle)
                if let fontWeight = fontWeight {
                    font = font.weight(fontWeight)
                }
                return font
            }
        } else {
            if let fontDesign = fontDesign {
                var font = Font.system(size: fontSize ?? 16, design: fontDesign)
                if let fontWeight = fontWeight {
                    font = font.weight(fontWeight)
                }
                return font
            } else {
                var font = Font.system(size: fontSize ?? 16)
                if let fontWeight = fontWeight {
                    font = font.weight(fontWeight)
                }
                return font
            }
        }
    }
    
    private var emojiSize: CGFloat {
        if let fontSize = fontSize {
            return fontSize * 1.2
        } else if let textStyle = textStyle {
            // Approximate sizes for text styles
            switch textStyle {
            case .largeTitle: return 34 * 1.2
            case .title: return 28 * 1.2
            case .title2: return 22 * 1.2
            case .title3: return 20 * 1.2
            case .headline: return 17 * 1.2
            case .body: return 17 * 1.2
            case .callout: return 16 * 1.2
            case .subheadline: return 15 * 1.2
            case .footnote: return 13 * 1.2
            case .caption: return 12 * 1.2
            case .caption2: return 11 * 1.2
            @unknown default: return 17 * 1.2
            }
        } else {
            return 16 * 1.2 // Default size
        }
    }
    
    var body: some View {
        let components = parseTextWithEmoji(text: text)
        
        // Use a more direct and stable approach with HStack
        improvedEmojiTextLayout(components: components)
            .lineLimit(lineLimit)
            .fixedSize(horizontal: false, vertical: true)
            // Ensure the view has a unique identifier for lists
            .id("\(viewID)-\(text)")
    }
    
    private func improvedEmojiTextLayout(components: [TextComponent]) -> some View {
        // Use LazyHStack for more efficient rendering in lists
        LazyHStack(alignment: .center, spacing: 0) {
            ForEach(components) { component in
                if component.isEmoji {
                    // Find the emoji in any of the dictionaries
                    if let emojiInfo = findEmoji(shortcode: component.text) {
                        // Create a specialized view for each emoji with its own loading logic
                        OptimizedEmojiView(
                            emojiCode: component.text,
                            emojiURL: emojiInfo.url,
                            emojiSize: emojiSize,
                            font: font,
                            textColor: textColor,
                            viewID: viewID,
                            serverDomain: emojiInfo.serverDomain
                        )
                    } else {
                        // Fallback text for unknown emoji
                        Text(":\(component.text):")
                            .font(font)
                            .foregroundColor(textColor)
                    }
                } else {
                    // Regular text
                    Text(component.text)
                        .font(font)
                        .foregroundColor(textColor)
                }
            }
        }
    }
    
    // New struct to track emoji information including server origin
    private struct EmojiInfo {
        let url: String
        let serverDomain: String
    }
    
    // Helper function to find an emoji across all dictionaries
    private func findEmoji(shortcode: String) -> EmojiInfo? {
        // First check the default emoji dictionary
        if let emoji = defaultEmojiDict[shortcode] {
            return EmojiInfo(url: emoji.url, serverDomain: "default")
        }
        
        // Then check all server-specific dictionaries
        for (domain, emojiDict) in emojiDicts {
            if let emoji = emojiDict[shortcode] {
                return EmojiInfo(url: emoji.url, serverDomain: domain)
            }
        }
        
        return nil
    }
    
    // Helper struct to track text components
    private struct TextComponent: Identifiable {
        let id = UUID()
        let text: String
        let isEmoji: Bool
    }
    
    // Parse the text string and separate emoji codes from regular text
    private func parseTextWithEmoji(text: String) -> [TextComponent] {
        var components: [TextComponent] = []
        var currentText = ""
        var inEmoji = false
        var currentEmoji = ""
        
        // Helper to add current text buffer as component
        func addCurrentTextIfNeeded() {
            if !currentText.isEmpty {
                components.append(TextComponent(text: currentText, isEmoji: false))
                currentText = ""
            }
        }
        
        // Helper to add current emoji buffer as component
        func addCurrentEmojiIfNeeded() {
            if !currentEmoji.isEmpty {
                components.append(TextComponent(text: currentEmoji, isEmoji: true))
                currentEmoji = ""
            }
        }
        
        // Iterate through each character
        for char in text {
            if char == ":" {
                if inEmoji {
                    // End of emoji
                    inEmoji = false
                    addCurrentEmojiIfNeeded()
                } else {
                    // Start of emoji
                    addCurrentTextIfNeeded()
                    inEmoji = true
                }
            } else if inEmoji {
                // We're inside an emoji code
                currentEmoji.append(char)
            } else {
                // Regular text
                currentText.append(char)
            }
        }
        
        // Add any remaining text or emoji
        addCurrentTextIfNeeded()
        if inEmoji {
            // Handle unclosed emoji code
            components.append(TextComponent(text: ":" + currentEmoji, isEmoji: false))
        }
        
        return components
    }
}

// A highly optimized view for displaying a single emoji
struct OptimizedEmojiView: View {
    let emojiCode: String
    let emojiURL: String
    let emojiSize: CGFloat
    let font: Font
    let textColor: Color?
    let viewID: UUID
    let serverDomain: String // Add server domain for better caching
    
    // Create a unique identifier for this specific emoji
    private var uniqueID: String {
        "\(viewID)-\(serverDomain)-\(emojiCode)-\(emojiURL.hashValue)"
    }
    
    // Use a cache to store loaded images
    @State private var loadedImage: UIImage? = nil
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: emojiSize)
            } else {
                Text(":\(emojiCode):")
                    .font(font)
                    .foregroundColor(textColor)
                    .frame(height: emojiSize)
            }
        }
        .id(uniqueID) // Ensure unique identification including server domain
        .onAppear {
            loadEmoji()
        }
    }
    
    private func loadEmoji() {
        guard loadedImage == nil, isLoading, let url = URL(string: emojiURL) else { return }
        
        // Use a dedicated URLSession for emoji loading
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    isLoading = false
                }
                return
            }
            
            if let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.loadedImage = image
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
        }
        task.resume()
    }
}
