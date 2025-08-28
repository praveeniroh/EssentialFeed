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
        expect(loader, toCompleteWithResult:.failure( .connectivity)) {
            let clientError = NSError(domain: "No Network", code: 299, userInfo: nil)
            client.complete(with: clientError)
        }
    }

    func test_load_deliverErrorOnNon200HttpResponse(){
        let (loader, client) = makeSUT()
        let sampleCodes = [199, 201, 300, 400, 500]

        sampleCodes.enumerated().forEach { index, code in
            expect(loader, toCompleteWithResult: .failure(.invalidData)) {
                client.complete(withStatusCode: code, at: index)
            }
        }
    }

    func test_load_deliverErrorOn200HttpResponseWithInvalidJSON(){
        let (loader, client) = makeSUT()
        expect(loader, toCompleteWithResult: .failure(.invalidData)) {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        }
    }

    func test_load_deliverNoItemOn200HtppResponseWithEmptyJSON(){
        let (loader, client) = makeSUT()
        expect(loader, toCompleteWithResult: .success([])) {
            let emptyListJson = Data("{\"items\": []}".utf8)
            client.complete(withStatusCode: 200, data: emptyListJson)
        }
    }

    func test_load_deliverItemOn200HtppResponseWithJSONItem(){
        let (loader, client) = makeSUT()
        let item1 = FeedItem(id: UUID(), description: nil, location: nil, imageURL: URL(string: "https://item1-imageurl.com")!)
        let item1JSON = [
            "id": item1.id.uuidString,
            "image": item1.imageURL.absoluteString
        ]

        let item2 = FeedItem(id: UUID(), description: "a description", location: "A location", imageURL: URL(string: "https://item2-imageurl.com")!)

        let item2JSON = [
            "id": item2.id.uuidString,
            "description": item2.description!,
            "location": item2.location!,
            "image": item2.imageURL.absoluteString
        ]

        let itemJSON = ["items": [item1JSON, item2JSON]]
        expect(loader, toCompleteWithResult: .success([item1, item2])) {
            let data = try! JSONSerialization.data(withJSONObject: itemJSON)
            client.complete(withStatusCode: 200, data: data)
        }
    }



    //MARK: Utils
    private func makeSUT(url: URL = URL(string: "https://example.com/feed")!) -> (loader: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let loader = RemoteFeedLoader(httpClient: client, url: url)
        return (loader, client)

    }

    private func expect(_ sut: RemoteFeedLoader, toCompleteWithResult result: RemoteFeedLoader.Result, when action: () -> Void,file: StaticString = #filePath, line: UInt = #line) {
        var capturedResult = [RemoteFeedLoader.Result]()
        sut.load { capturedResult.append($0)}
        action()
        XCTAssertEqual(capturedResult, [result], file: file, line: line)
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
