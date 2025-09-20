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
        session.dataTask(with: url) { _, _, error in
            if let error {
                completion(.failure(error))
            }
        }.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {

    func test_getFromURL_resumeDataTaskWithError() {
        URLProtocolStub.startInterceptingRequest()
        let url = URL(string: "https://some-url.com")!
        let error = NSError(domain: "Some error", code: 1)
        URLProtocolStub.stub(for: url, data: nil, response: nil, error: error)

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
        URLProtocolStub.stopInterceptingRequest()
    }
    //MARK: Helpers
    private class URLProtocolStub: URLProtocol {
        private static var stubs: [URL: Stub] = [:]

        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }

        static func stub(for url: URL,data: Data?, response: URLResponse?, error: Error?) {
            stubs[url] = Stub(data: data, response: response, error: error)
        }

        static func startInterceptingRequest() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }

        static func stopInterceptingRequest() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
        }

        override class func canInit(with request: URLRequest) -> Bool {
            guard let url = request.url else {
                return false
            }
            return stubs[url] != nil
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {
            guard let url = request.url, let stub = URLProtocolStub.stubs[url] else { return }
            if let data = stub.data {
                client?.urlProtocol(self, didLoad: data)
            }

            if let response = stub.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }

            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }
}
