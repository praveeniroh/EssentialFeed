//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Praveenraj T on 18/09/25.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClient {
    private let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error {
                completion(.failure(error))
            }
        }.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {

    func test_getFromURL_resumeDataTaskWithURL() {
        let url = URL(string: "https://some-url.com")!
        let session = URLSessionSpy()
        let task = URLSessionDataTaskSpy()
        session.stubDataTask(for: url, dataTask: task)
        let sut = URLSessionHTTPClient(session: session)
        sut.get(from: url) {_ in}
        XCTAssertEqual(task.resumeCallCount, 1)
    }

    func test_getFromURL_resumeDataTaskWithError() {
        let url = URL(string: "https://some-url.com")!
        let error = NSError(domain: "SOme error", code: 1)
        let session = URLSessionSpy()
        let task = URLSessionDataTaskSpy()
        session.stubDataTask(for: url, error: error)
        let sut = URLSessionHTTPClient(session: session)
        let expect = expectation(description: "Wait for error completion")
        sut.get(from: url) {result in
            switch result {
                case .failure(let capturedError as NSError):
                XCTAssertEqual(capturedError, error)
            default:
                XCTFail("Expected failure with error \(error), but received \(result)")
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }
    //MARK: Helpers
    private class URLSessionSpy: URLSession {
        private var stub: [URL: Stub] = [:]

        private struct Stub {
            let dataTask: URLSessionDataTask
            let error: Error?
        }

        override init(){
            super.init()
        }

        func stubDataTask(for url: URL, dataTask: URLSessionDataTask = FakeURLSessionDataTask(), error: Error? = nil) {
            stub[url] = Stub(dataTask: dataTask, error: error)
        }

        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            guard let taskStub = stub[url] else {
                fatalError("No stubbing defined for \(url)")
            }
            
            completionHandler(nil, nil, taskStub.error)
            return taskStub.dataTask ?? FakeURLSessionDataTask()
        }
    }

    private class FakeURLSessionDataTask: URLSessionDataTask {
        override func resume() {}
    }

    private class URLSessionDataTaskSpy: URLSessionDataTask {
        var resumeCallCount: Int = 0
        override func resume() {
            resumeCallCount += 1
        }
    }
}
