//
//  LoadFeedFromRemoteUsecaseTests.swift
//  EssentialFeedTests
//
//  Created by praveen-12298 on 22/08/25.
//

import XCTest
import EssentialFeed

final class LoadFeedFromRemoteUsecaseTests: XCTestCase {
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
        expect(loader, toCompleteWithResult:failure(.connectivity)) {
            let clientError = NSError(domain: "No Network", code: 299, userInfo: nil)
            client.complete(with: clientError)
        }
    }

    func test_load_deliverErrorOnNon200HttpResponse(){
        let (loader, client) = makeSUT()
        let sampleCodes = [199, 201, 300, 400, 500]

        sampleCodes.enumerated().forEach { index, code in
            expect(loader, toCompleteWithResult: .failure(RemoteFeedLoader.Error.invalidData)) {
                let jsonData = makeItemJSONData([])
                client.complete(withStatusCode: code, data: jsonData, at: index)
            }
        }
    }

    func test_load_deliverErrorOn200HttpResponseWithInvalidJSON(){
        let (loader, client) = makeSUT()
        expect(loader, toCompleteWithResult: failure(.invalidData)) {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        }
    }

    func test_load_deliverNoItemOn200HtppResponseWithEmptyJSON(){
        let (loader, client) = makeSUT()
        expect(loader, toCompleteWithResult: .success([])) {
            let emptyListJson = makeItemJSONData([])
            client.complete(withStatusCode: 200, data: emptyListJson)
        }
    }

    func test_load_deliverItemOn200HtppResponseWithJSONItem(){
        let (loader, client) = makeSUT()
        let item1 = makeItem(
            id: UUID(),
            imageURL: URL(string: "https://item1-imageurl.com")!
        )
        let item2 = makeItem(
            id: UUID(),
            description: "a description",
            location: "A location",
            imageURL: URL(string: "https://item2-imageurl.com")!
        )
        expect(loader, toCompleteWithResult: .success([item1.model, item2.model])) {
            let data = makeItemJSONData([item1.json, item2.json])
            client.complete(withStatusCode: 200, data: data)
        }
    }

    func test_load_doesNotDeliverResultAfterSUTInstaceHasBeenDeallocated() {
        let url = URL(string: "https://example.com/feed")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(httpClient: client, url: url)
        var capturedResult = [RemoteFeedLoader.Result]()

        sut?.load{ capturedResult.append($0)}
        sut = nil

        client.complete(withStatusCode: 200, data: makeItemJSONData([]))

        XCTAssertTrue(capturedResult.isEmpty)
    }


    //MARK: Utils
    private func makeSUT(url: URL = URL(string: "https://example.com/feed")!, file: StaticString = #filePath, line: UInt = #line) -> (loader: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let loader = RemoteFeedLoader(httpClient: client, url: url)
        trackForMemoryLead(loader, file: file, line: line)
        trackForMemoryLead(client, file: file, line: line)
        return (loader, client)

    }

    private func makeItem(id: UUID = UUID(), description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]){
        let feedItem = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        let json: [String: Any] = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].reduce(into: [String: Any]()) { result, element in
            if element.value != nil {
                result[element.key] = element.value
            }
        }
        return (feedItem, json)
    }

    private func makeItemJSONData(_ items: [[String: Any]]) -> Data {
        let items = ["items": items]
        return try!  JSONSerialization.data(withJSONObject: items, options: [])
    }

    private func expect(_ sut: RemoteFeedLoader, toCompleteWithResult expectedResult: RemoteFeedLoader.Result, when action: () -> Void,file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expctedItems)):
                XCTAssertEqual(receivedItems, expctedItems, file: file, line: line)
            case let(.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError, expectedError)
            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)
    }

    private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        .failure(error)
    }

    private class HTTPClientSpy: HTTPClient {
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        var requestedURLs: [URL]{
            messages.map{$0.url}
        }
        func get(from url: URL, onCompletion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, onCompletion))
        }

        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure( error))
        }

        func complete(withStatusCode code: Int,data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: messages[index].url,
                statusCode: code,
                httpVersion: nil,
                headerFields: nil)!
            messages[index].completion(.success(data, response))
        }
    }
}
