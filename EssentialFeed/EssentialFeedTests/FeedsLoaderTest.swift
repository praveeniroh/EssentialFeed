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
                let jsonData = makeItemJSONData([])
                client.complete(withStatusCode: code, data: jsonData, at: index)
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



    //MARK: Utils
    private func makeSUT(url: URL = URL(string: "https://example.com/feed")!) -> (loader: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let loader = RemoteFeedLoader(httpClient: client, url: url)
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
