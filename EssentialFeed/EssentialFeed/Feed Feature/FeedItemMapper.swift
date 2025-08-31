//
//  FeedItemMapper.swift
//  EssentialFeed
//
//  Created by Praveenraj T on 30/08/25.
//

import Foundation

internal struct FeedItemMapper {
    private struct Root: Decodable {
        let items: [Item]

        var feedItems: [FeedItem] {
            items.map(\.self.feedItem)
        }
    }

    private struct Item: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL

        var feedItem: FeedItem {
            FeedItem(id: id, description: description, location: location, imageURL: image)
        }
    }

    private static var OK_200: Int {
        return 200
    }

    internal static func map(_ data: Data, _ response: HTTPURLResponse) -> RemoteFeedLoader.Result {
        guard response.statusCode == OK_200, let root = try? JSONDecoder().decode(Root.self, from: data) else {
            return .failure(RemoteFeedLoader.Error.invalidData)
        }
        return .success(root.feedItems)
    }
}
