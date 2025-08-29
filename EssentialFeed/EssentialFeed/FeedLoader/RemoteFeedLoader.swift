//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by praveen-12298 on 23/08/25.
//

import Foundation

public enum HTTPClientResult{
    case success(Data,HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func load(from url: URL, onCompletion: @escaping (HTTPClientResult) -> Void)
}

public final class RemoteFeedLoader {
    private let httpClient: HTTPClient
    private let url: URL

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }

    public init(httpClient: HTTPClient, url: URL) {
        self.httpClient = httpClient
        self.url = url
    }

    public func load(onCompletion: @escaping (Result) -> Void) {
        httpClient.load(from: url, onCompletion: { response in
            switch response {
            case let .success(data, response):
                do {
                    let feedItem = try FeedItemMapper.map(data, response)
                    onCompletion(.success(feedItem))
                } catch {
                    onCompletion(.failure(.invalidData))
                }
            case .failure:
                onCompletion(.failure(.connectivity))
            }
        })
    }
}

struct FeedItemMapper {
    private struct Root: Decodable {
        let items: [Item]
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

    static var OK_200: Int {
        return 200
    }

    static func map(_ data: Data, _ response: HTTPURLResponse)throws -> [FeedItem] {
        if response.statusCode == OK_200 {
            let root = try JSONDecoder().decode(Root.self, from: data)
            return root.items.map(\.self.feedItem)
        } else {
            throw RemoteFeedLoader.Error.invalidData
        }
    }
}
