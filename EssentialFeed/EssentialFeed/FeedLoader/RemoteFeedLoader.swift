//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by praveen-12298 on 23/08/25.
//

import Foundation

public protocol HTTPClient {
    func load(from url: URL)
}

public final class RemoteFeedLoader {
    private let httpClient: HTTPClient
    private let url: URL

    public init(httpClient: HTTPClient, url: URL) {
        self.httpClient = httpClient
        self.url = url
    }

    public func load() {
        httpClient.load(from: url)
    }
}
