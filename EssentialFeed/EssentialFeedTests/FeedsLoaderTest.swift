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
        let (_,client) = getFeedLoaderAndClient()
        XCTAssertNil(client.url)
    }

    func test_load_requestsDataFromURL() {
        let url = URL( string:"https://example.com/feed")!
        let (loader, client) = getFeedLoaderAndClient(url: url)
        loader.load()
        XCTAssertNotNil(client.url)
    }

    func test_loadTwice_requestsDataFromURLTwice_Success(){
        let url = URL( string:"https://example.com/feed")!
        let (loader, client) = getFeedLoaderAndClient(url: url)
        loader.load()
        loader.load()
        ///Failed when loader internally called cleint.load multiple times
        XCTAssertEqual([url,url], client.requestedURLs)
    }

    func test_loadTwice_requestsDataFromURLTwice_Failure(){
        let url = URL( string:"https://example.com/feed")!
        let (loader, client) = getFeedLoaderAndClient(url: url)
        loader.load()
        loader.load()
        XCTAssertNotEqual([url], client.requestedURLs)
    }
    //MARK: Utils
    private func getFeedLoaderAndClient(url: URL = URL(string: "https://example.com/feed")!) -> (loader: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let loader = RemoteFeedLoader(httpClient: client, url: url)
        return (loader, client)

    }

    private class HTTPClientSpy: HTTPClient {
        var url: URL?
        var requestedURLs: [URL] = []
        func load(from url: URL) {
            self.url = url
            requestedURLs.append(url)
            print(">>> Loading data from \(url)")
        }
    }
}
