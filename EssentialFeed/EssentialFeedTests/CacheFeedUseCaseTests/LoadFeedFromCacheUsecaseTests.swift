//
//  LoadFeedFromCacheUsecaseTests.swift
//  EssentialFeedTests
//
//  Created by Praveenraj T on 29/10/25.
//

import XCTest
import EssentialFeed

final class LoadFeedFromCacheUsecaseTests: XCTestCase {
    func test_init_doesNotDeleteCacheUponDeletion() {
        let (_,store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_load_requestsCacheRetrival() {
        let (sut,store) = makeSUT()
        sut.load {_ in}
        XCTAssertEqual(store.receivedMessages, [.retrive])
    }

    func test_load_failsOnRetrivalError() {
        let (sut,store) = makeSUT()
        let retrivalError = anyNSError()
        let exp = expectation(description: "Wait for load completion")
        var capturedError: Error?
        sut.load { result in
            switch result {
            case .failure(let error):
                capturedError = error
            default:
                XCTFail("Expected failure but \(result.debugDescription) received")
            }
            exp.fulfill()
        }
        store.completeRetrival(with: retrivalError)
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(capturedError as? NSError, retrivalError)
    }

    func test_load_deliversNoImagesOnEmptyCache() {
        let (sut,store) = makeSUT()
        let retrivalError = anyNSError()
        let exp = expectation(description: "Wait for load completion")
        var capturedImage: [FeedImage]?
        sut.load { result in
            switch result {
            case .success(let image):
                capturedImage = image
            default:
                XCTFail("Expected failure but \(result.debugDescription) received")
            }
            exp.fulfill()
        }
        store.completeWithEmptyCache()
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(capturedImage, [])
    }

    //MARK: - Helpers
    private func makeSUT(timeStamp: @autoclosure @escaping () -> Date = Date.init(), file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: timeStamp())
        trackForMemoryLead(sut, file: file, line: line)
        trackForMemoryLead(store, file: file, line: line)
        return (sut, store)
    }

    private func anyNSError() -> NSError {
        NSError(domain: "Any Error", code: 0)
    }
}
