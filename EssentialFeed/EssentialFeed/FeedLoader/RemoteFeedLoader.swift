//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by praveen-12298 on 23/08/25.
//

import Foundation

public protocol HTTPClient {
    func load(from url: URL, onCompletion: @escaping (Error) -> Void)
}

public final class RemoteFeedLoader {
    private let httpClient: HTTPClient
    private let url: URL

    public enum Error: Swift.Error {
        case connectivity
    }

    public init(httpClient: HTTPClient, url: URL) {
        self.httpClient = httpClient
        self.url = url
    }

    public func load(onCompletion: @escaping (Error) -> Void = {_ in}) {
        httpClient.load(from: url, onCompletion: { _ in onCompletion(.connectivity)})
    }
}
