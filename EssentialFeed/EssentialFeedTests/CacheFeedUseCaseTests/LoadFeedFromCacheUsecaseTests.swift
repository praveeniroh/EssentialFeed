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
        expect(sut, .failure(retrivalError)) {
            store.completeRetrival(with: retrivalError)
        }
    }

    func test_load_deliversNoImagesOnEmptyCache() {
        let (sut,store) = makeSUT()
        expect(sut, .success([])) {
            store.completeRetrivalWithEmptyCache()
        }
    }

    func test_load_deliversCacheImagesOnLessThanSevenDaysOldCache() {
        let fixedCurrentData = Date()
        let (sut,store) = makeSUT(fixedCurrentData: {
            fixedCurrentData
        }())
        let feed = uniqueImageFeed()
        let lessThan7DaysTimeStap = fixedCurrentData.adding(days: -7).adding(seconds: 1)
        expect(sut, .success(feed.models)) {
            store.completeRetrival(with: feed.local, timeStamp: lessThan7DaysTimeStap)
        }
    }

    func test_load_deliversNoImagesOnSevenDaysOldCache() {
        let fixedCurrentData = Date()
        let (sut,store) = makeSUT(fixedCurrentData: {
            fixedCurrentData
        }())
        let feed = uniqueImageFeed()
        let sevenDaysTimeStap = fixedCurrentData.adding(days: -7)
        expect(sut, .success([])) {
            store.completeRetrival(with: feed.local, timeStamp: sevenDaysTimeStap)
        }
    }

    //MARK: - Helpers
    private func makeSUT(fixedCurrentData: @autoclosure @escaping () -> Date = Date.init(), file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: fixedCurrentData())
        trackForMemoryLead(sut, file: file, line: line)
        trackForMemoryLead(store, file: file, line: line)
        return (sut, store)
    }

    private func expect(_ sut: LocalFeedLoader, _ expectedResult: LoadFeedResult, _ action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")

        sut.load { receivedResult in
            switch(receivedResult, expectedResult) {
            case let (.success(receivedImages), .success(expectedImages)):
                XCTAssertEqual(receivedImages, expectedImages)
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError, expectedError)
            default:
                XCTFail("Expected \(expectedResult), but got \(String(describing: receivedResult))")
            }
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)
    }

    private func anyNSError() -> NSError {
        NSError(domain: "Any Error", code: 0)
    }

    private func uniqueImage() -> FeedImage {
        FeedImage(id: UUID(), description: "Any", location: "Any", url: anyURL())
    }

    private func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
        let models = [uniqueImage(), uniqueImage()]
        let local = models.map {LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
        return (models, local)
    }

    private func anyURL() -> URL {
        return URL(string: "https://some-url.com")!
    }
}

private extension Date {
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }

    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
