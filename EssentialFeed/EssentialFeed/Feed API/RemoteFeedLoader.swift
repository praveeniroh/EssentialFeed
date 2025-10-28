//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by praveen-12298 on 23/08/25.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
    private let httpClient: HTTPClient
    private let url: URL

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public typealias Result = LoadFeedResult

    public init(httpClient: HTTPClient, url: URL) {
        self.httpClient = httpClient
        self.url = url
    }

    public func load(completion onCompletion: @escaping (Result) -> Void) {
        httpClient.get(from: url, onCompletion: { [weak self] response in
            guard self != nil else {return}
            switch response {
            case let .success(data, response):
                onCompletion(RemoteFeedLoader.map(data, respone: response))
            case .failure:
                onCompletion(.failure(Error.connectivity))
            }
        })
    }

    private static func map(_ data: Data, respone: HTTPURLResponse) -> Result {
        do {
            let items = try FeedItemMapper.map(data, respone)
            return .success(items.toModel())
        } catch {
            return .failure(error)
        }
    }
}

private extension Array where Element == RemoteFeedItem {
    func toModel() -> [FeedImage] {
        return map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.image)}
    }
}
