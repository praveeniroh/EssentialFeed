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
        let (_,client) = makeSUT()
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    func test_load_requestsDataFromURL() {
        let url = URL( string:"https://example.com/feed")!
        let (loader, client) = makeSUT(url: url)
        loader.load()
        XCTAssertEqual(client.requestedURLs.count,1)
    }

    func test_loadTwice_requestsDataFromURLTwice_Success(){
        let url = URL( string:"https://example.com/feed")!
        let (loader, client) = makeSUT(url: url)
        loader.load()
        loader.load()
        ///Failed when loader internally called cleint.load multiple times
        XCTAssertEqual([url,url], client.requestedURLs)
    }

    func test_loadTwice_requestsDataFromURLTwice_Failure(){
        let url = URL( string:"https://example.com/feed")!
        let (loader, client) = makeSUT(url: url)
        loader.load()
        loader.load()
        XCTAssertNotEqual([url], client.requestedURLs)
    }

    func test_load_deliverErrorOnClientError(){
        let (loader, client) = makeSUT()
        client.error = NSError(domain: "No Network", code: 299, userInfo: nil)
        var capturedErrors = [RemoteFeedLoader.Error]()
        loader.load { capturedErrors.append($0)}
        XCTAssertEqual(capturedErrors, [.connectivity])
    }

    //MARK: Utils
    private func makeSUT(url: URL = URL(string: "https://example.com/feed")!) -> (loader: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let loader = RemoteFeedLoader(httpClient: client, url: url)
        return (loader, client)

    }

    private class HTTPClientSpy: HTTPClient {
        var requestedURLs: [URL] = []
        var error:Error?
        func load(from url: URL, onCompletion: @escaping (Error) -> Void) {
            if let error = error {
                onCompletion(error)
                return
            }
            requestedURLs.append(url)
            print(">>> Loading data from \(url)")
        }
    }
}
