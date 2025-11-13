//
//  ValidateFeedCacheUsecaseTests.swift
//  EssentialFeedTests
//
//  Created by Praveenraj T on 13/11/25.
//

import XCTest
import EssentialFeed

final class ValidateFeedCacheUsecaseTests: XCTestCase {
    func test_init_doesNotDeleteCacheUponDeletion() {
        let (_,store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_validate_deleteCacheOnRetrivalError() {
        let (sut, store) = makeSUT()
        sut.validateCache()
        store.completeRetrival(with: anyNSError())
        XCTAssertEqual(store.receivedMessages, [.retrive, .deleteCachedFeed])
    }

    func test_validate_doesNotDeleteCacheOnEmptyCache() {
        let (sut, store) = makeSUT()
        sut.validateCache()
        store.completeRetrivalWithEmptyCache()
        XCTAssertEqual(store.receivedMessages, [.retrive])
    }

    func test_validate_doesNotDeleteCacheOnLessThanSevenDaysOldCache() {
        let fixedCurrentData = Date()
        let (sut,store) = makeSUT(fixedCurrentData: {
            fixedCurrentData
        }())
        let feed = uniqueImageFeed()
        let lessThanSevenDaysTimeStap = fixedCurrentData.adding(days: -7).adding(seconds: 1)

        sut.validateCache()
        store.completeRetrival(with: feed.local, timeStamp: lessThanSevenDaysTimeStap)

        XCTAssertEqual(store.receivedMessages, [.retrive])
    }



    //MARK: - Helpers
    private func makeSUT(fixedCurrentData: @autoclosure @escaping () -> Date = Date.init(), file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: fixedCurrentData())
        trackForMemoryLead(sut, file: file, line: line)
        trackForMemoryLead(store, file: file, line: line)
        return (sut, store)
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
