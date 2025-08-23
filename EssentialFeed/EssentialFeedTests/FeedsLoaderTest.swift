//
//  FeedsLoaderTest.swift
//  EssentialFeedTests
//
//  Created by praveen-12298 on 22/08/25.
//

import XCTest
import EssentialFeed

final class RemoteFeedsLoaderTest: XCTestCase {
    func test_init_doNotRequestsDataFromURL() {
        let client = HTTPClientSpy()
        _ = RemoteFeedLoader(httpClient: client, url: URL(string:"https://example.com")!)
        XCTAssertNil(client.url)
    }

    func test_load_requestsDataFromURL() {
        let client = HTTPClientSpy()
        let url = URL( string:"https://example.com/feed")!
        let loader = RemoteFeedLoader(httpClient: client, url: url)
        loader.load()
        XCTAssertNotNil(client.url)
    }


    private class HTTPClientSpy: HTTPClient {
        var url: URL?
        func load(from url: URL) {
            self.url = url
            print(">>> Loading data from \(url)")
        }
    }
}
