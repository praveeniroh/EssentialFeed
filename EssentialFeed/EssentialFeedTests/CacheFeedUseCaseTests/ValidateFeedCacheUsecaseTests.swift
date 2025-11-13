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
}
