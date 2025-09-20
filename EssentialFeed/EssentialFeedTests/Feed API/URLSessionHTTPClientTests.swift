//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Praveenraj T on 18/09/25.
//

import XCTest
import EssentialFeed
protocol HTTPSession {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask
}

protocol HTTPSessionTask {
    func resume()
}

class URLSessionHTTPClient {
    private let session: HTTPSession

    init(session: HTTPSession) {
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
    private class URLSessionSpy: HTTPSession {
        private var stub: [URL: Stub] = [:]

        private struct Stub {
            let dataTask: HTTPSessionTask
            let error: Error?
        }

        func stubDataTask(for url: URL, dataTask: HTTPSessionTask = FakeURLSessionDataTask(), error: Error? = nil) {
            stub[url] = Stub(dataTask: dataTask, error: error)
        }

        func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask {
            guard let taskStub = stub[url] else {
                fatalError("No stubbing defined for \(url)")
            }
            
            completionHandler(nil, nil, taskStub.error)
            return taskStub.dataTask
        }
    }

    private class FakeURLSessionDataTask: HTTPSessionTask {
        func resume() {}
    }

    private class URLSessionDataTaskSpy: HTTPSessionTask {
        var resumeCallCount: Int = 0
        func resume() {
            resumeCallCount += 1
        }
    }
}
