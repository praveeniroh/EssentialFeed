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

    public typealias Result = LoadFeedResult<Error>

    public init(httpClient: HTTPClient, url: URL) {
        self.httpClient = httpClient
        self.url = url
    }

    public func load(completion onCompletion: @escaping (Result) -> Void) {
        httpClient.load(from: url, onCompletion: { [weak self] response in
            guard self != nil else {return}
            switch response {
            case let .success(data, response):
                onCompletion( FeedItemMapper.map(data, response))
            case .failure:
                onCompletion(.failure(Error.connectivity))
            }
        })
    }
}
