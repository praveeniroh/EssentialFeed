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

    struct UnexpectedValuesRepresentaionError: Error {}

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
//        let url = URL(string: "https://somewrong-url.com")! //URL Mismatch Failing case
        session.dataTask(with: url) { _, _, error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.failure(UnexpectedValuesRepresentaionError())) // Error supplied is nil
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
        let url = anyURL()

        let expectation = expectation(description: "Wait for GET request ")
        URLProtocolStub.observeReqeust{ request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            expectation.fulfill()
        }
        makeSUT().get(from: url) { _ in }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_getFromURL_resumeDataTaskWithError() {
        let requestError = NSError(domain: "Some error", code: 1)
        let receivedError = resultError(data: nil, response: nil, error: requestError)
        XCTAssertEqual(requestError.code, (receivedError as NSError?)?.code)
        XCTAssertEqual(requestError.domain, (receivedError as NSError?)?.domain)
    }

    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        let anyData = Data("Any data".utf8)
        let anyError = NSError(domain: "Any Error", code: 0)
        let nonHTTPURLResponse = URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let anyHTTPURLResponse = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)
        XCTAssertNotNil(resultError(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultError(data: nil, response: nonHTTPURLResponse, error: nil))
        XCTAssertNotNil(resultError(data: nil, response: anyHTTPURLResponse, error: nil))
        XCTAssertNotNil(resultError(data: anyData, response: nil, error: nil))
        XCTAssertNotNil(resultError(data: anyData, response: nil, error: anyError))
        XCTAssertNotNil(resultError(data: nil, response: nonHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultError(data: nil, response: anyHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultError(data: anyData, response: anyHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultError(data: anyData, response: nonHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultError(data: anyData, response: nonHTTPURLResponse, error: nil))
    }

    //MARK: Helpers

    private func makeSUT( file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLead(sut,file: file, line: line)
        return sut
    }

    private func resultError(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> Error? {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)

        let expect = expectation(description: "Wait for error completion")
        var receivedError: Error?
        sut.get(from: anyURL()) {result in
            switch result {
            case .failure(let error):
                receivedError = error
            default:
                XCTFail("Expected failure ,but received \(result)",file: file, line: line)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
        return receivedError
    }

    private func anyURL() -> URL {
        return URL(string: "https://some-url.com")!
    }

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
