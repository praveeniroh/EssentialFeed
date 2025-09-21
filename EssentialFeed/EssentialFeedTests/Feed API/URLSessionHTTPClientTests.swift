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

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
//        let url = URL(string: "https://somewrong-url.com")! //URL Mismatch Failing case
        session.dataTask(with: url) { _, _, error in
            if let error {
                completion(.failure(error))
            }
        }.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {

    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequest()
    }

    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequest()
    }

    func test_getFromURL_performGETRequestWithURL() {
        let url = URL(string: "https://some-url.com")!

        let expectation = expectation(description: "Wait for GET request ")
        URLProtocolStub.observeReqeust{ request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            expectation.fulfill()
        }
        URLSessionHTTPClient().get(from: url) { _ in }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_getFromURL_resumeDataTaskWithError() {
        let url = URL(string: "https://some-url.com")!
        let error = NSError(domain: "Some error", code: 1)
        URLProtocolStub.stub(data: nil, response: nil, error: error)

        let sut = URLSessionHTTPClient()

        let expect = expectation(description: "Wait for error completion")
        sut.get(from: url) {result in
            switch result {
                case .failure(let capturedError as NSError):
                XCTAssertEqual(capturedError.domain, error.domain)
                XCTAssertEqual(capturedError.code, error.code)
            default:
                XCTFail("Expected failure with error \(error), but received \(result)")
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }
    //MARK: Helpers
    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?

        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }

        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }

        static func observeReqeust(observer: ((URLRequest) -> Void)?) {
            requestObserver = observer
        }

        static func startInterceptingRequest() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }

        static func stopInterceptingRequest() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }

        override class func canInit(with request: URLRequest) -> Bool {
            Self.requestObserver?(request)
            return true //Intercepting all requests
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }

            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }

            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }
}
