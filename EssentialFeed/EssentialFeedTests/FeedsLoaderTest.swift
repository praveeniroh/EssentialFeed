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
        loader.load() {_ in}
        XCTAssertEqual(client.requestedURLs.count,1)
    }

    func test_loadTwice_requestsDataFromURLTwice_Success(){
        let url = URL( string:"https://example.com/feed")!
        let (loader, client) = makeSUT(url: url)
        loader.load() {_ in}
        loader.load() {_ in}
        ///Failed when loader internally called cleint.load multiple times
        XCTAssertEqual([url,url], client.requestedURLs)
    }

    func test_loadTwice_requestsDataFromURLTwice_Failure(){
        let url = URL( string:"https://example.com/feed")!
        let (loader, client) = makeSUT(url: url)
        loader.load() {_ in}
        loader.load() {_ in}
        XCTAssertNotEqual([url], client.requestedURLs)
    }

    func test_load_deliverErrorOnClientError(){
        let (loader, client) = makeSUT()
        expect(loader, toCompleteWithError: .connectivity) {
            let clientError = NSError(domain: "No Network", code: 299, userInfo: nil)
            client.complete(with: clientError)
        }
    }

    func test_load_deliverErrorOnNon200HttpResponse(){
        let (loader, client) = makeSUT()
        let sampleCodes = [199, 201, 300, 400, 500]

        sampleCodes.enumerated().forEach { index, code in
            expect(loader, toCompleteWithError: .invalidData) {
                client.complete(withStatusCode: code, at: index)
            }
        }
    }

    func test_load_deliverErrorOn200HttpResponseWithInvalidJSON(){
        let (loader, client) = makeSUT()
        expect(loader, toCompleteWithError: .invalidData) {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        }
    }


    //MARK: Utils
    private func makeSUT(url: URL = URL(string: "https://example.com/feed")!) -> (loader: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let loader = RemoteFeedLoader(httpClient: client, url: url)
        return (loader, client)

    }

    private func expect(_ sut: RemoteFeedLoader, toCompleteWithError error: RemoteFeedLoader.Error, when action: () -> Void,file: StaticString = #filePath, line: UInt = #line) {
        var capturedResult = [RemoteFeedLoader.Result]()
        sut.load { capturedResult.append($0)}
        action()
        XCTAssertEqual(capturedResult, [.failure(error)], file: file, line: line)
    }
    private class HTTPClientSpy: HTTPClient {
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        var requestedURLs: [URL]{
            messages.map{$0.url}
        }
        func load(from url: URL, onCompletion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, onCompletion))
        }

        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure( error))
        }

        func complete(withStatusCode code: Int,data: Data = Data(), at index: Int = 0) {
            let response = HTTPURLResponse(
                url: messages[index].url,
                statusCode: code,
                httpVersion: nil,
                headerFields: nil)!
            messages[index].completion(.success(data, response))
        }
    }
}
