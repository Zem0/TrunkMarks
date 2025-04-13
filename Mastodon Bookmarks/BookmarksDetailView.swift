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
    @State private var contentHeight: CGFloat = 200 // Default height

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Use HTML content viewer instead of EmojiTextView for proper rendering
                HTMLContentView(
                    htmlContent: status.content,
                    onHeightChange: { height in
                        contentHeight = height
                    }
                )
                .frame(height: contentHeight)
                .padding(.horizontal)

                // Display media attachments (images)
                VStack(spacing: 12) {
                    ForEach(status.media_attachments.filter { $0.type == "image" }, id: \.id) { media in
                        if let url = URL(string: media.url) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(height: 200)
                                        .frame(maxWidth: .infinity)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(12)
                                case .failure:
                                    Image(systemName: "photo")
                                        .font(.system(size: 50))
                                        .frame(height: 200)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(12)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Link to the post on Mastodon
                if let url = URL(string: "https://\(instanceDomain)/@\(status.account.username)/\(status.id)") {
                    Link("View on Mastodon", destination: url)
                        .font(.caption)
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
                            Image(systemName: "person.circle.fill")
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
                        .font(.headline)
                }
            }
        }
        .onAppear {
            // Fetch emoji data for the current instance domain if the cache is stale
            if emojiViewModel.isCacheStale(for: instanceDomain) {
                emojiViewModel.fetchCustomEmoji(for: instanceDomain)
            }
        }
    }
}

// HTML Content rendering view using WKWebView
struct HTMLContentView: UIViewRepresentable {
    let htmlContent: String
    var onHeightChange: ((CGFloat) -> Void)?
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        
        // Add script message handler for height updates
        userContentController.add(context.coordinator, name: "heightUpdate")
        userContentController.add(context.coordinator, name: "linkClicked")
        configuration.userContentController = userContentController
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.scrollView.isScrollEnabled = false
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Create HTML with proper styling and viewport settings
        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    font-size: 17px;
                    line-height: 1.5;
                    margin: 0;
                    padding: 0;
                    overflow-wrap: break-word;
                }
                
                a {
                    color: #1D9BF0;
                    text-decoration: none;
                }
                
                p {
                    margin-bottom: 16px;
                }
                
                img, video {
                    max-width: 100%;
                    height: auto;
                    border-radius: 8px;
                }
                
                @media (prefers-color-scheme: dark) {
                    body {
                        color: #FFFFFF;
                        background-color: transparent;
                    }
                    a {
                        color: #1DA1F2;
                    }
                }
            </style>
        </head>
        <body>
            <div id="content">
                \(htmlContent)
            </div>
            <script>
                // Calculate and send content height
                function updateHeight() {
                    const height = document.getElementById('content').offsetHeight;
                    window.webkit.messageHandlers.heightUpdate.postMessage(height);
                }
                
                // Handle external links
                document.addEventListener('click', function(e) {
                    if (e.target.tagName === 'A') {
                        e.preventDefault();
                        window.webkit.messageHandlers.linkClicked.postMessage(e.target.href);
                    }
                });
                
                // Update height when content changes
                window.onload = updateHeight;
                window.onresize = updateHeight;
                
                // Observe DOM changes to recalculate height
                const observer = new MutationObserver(updateHeight);
                observer.observe(document.body, { 
                    childList: true, 
                    subtree: true,
                    attributes: true,
                    characterData: true
                });
            </script>
        </body>
        </html>
        """
        
        uiView.loadHTMLString(htmlString, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: HTMLContentView
        
        init(_ parent: HTMLContentView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Calculate initial height after page loads
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "heightUpdate", let height = message.body as? CGFloat {
                // Update content height
                DispatchQueue.main.async {
                    // Add a little padding to ensure content isn't cut off
                    self.parent.onHeightChange?(height + 20)
                }
            } else if message.name == "linkClicked", let urlString = message.body as? String, let url = URL(string: urlString) {
                // Open external links in Safari
                UIApplication.shared.open(url)
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Allow initial load but capture link navigation
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}
