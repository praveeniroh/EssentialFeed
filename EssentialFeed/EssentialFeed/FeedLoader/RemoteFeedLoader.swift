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

    public init(httpClient: HTTPClient, url: URL) {
        self.httpClient = httpClient
        self.url = url
    }

    public func load(onCompletion: @escaping (Error) -> Void) {
        httpClient.load(from: url, onCompletion: { response in
            switch response {
            case .success:
                onCompletion(.invalidData)
            case .failure:
                onCompletion(.connectivity)
            }
        })
    }
}
