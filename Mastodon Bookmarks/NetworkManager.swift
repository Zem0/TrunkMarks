//
//  NetworkManager.swift
//  Mastodon Bookmarks
//
//  Created by Duncan Horne on 06/04/2025.
//

import Foundation

class NetworkManager {
    static let shared = NetworkManager()

    func fetchBookmarks(for user: String, completion: @escaping (Result<Data, Error>) -> Void) {
        // Replace with your actual API request code
        let url = URL(string: "https://yourapi.com/bookmarks")!
        var request = URLRequest(url: url)
        request.addValue("Bearer your_token_here", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0, userInfo: nil)))
                return
            }
            completion(.success(data))
        }.resume()
    }

    // Parsing the response data into a list of Bookmarks
    func parseBookmarksResponse(data: Data) -> [Bookmark] {
        do {
            let decoder = JSONDecoder()
            let posts = try decoder.decode([Bookmark].self, from: data)
            return posts
        } catch {
            print("Error parsing bookmarks response: \(error)")
            return []
        }
    }
}
