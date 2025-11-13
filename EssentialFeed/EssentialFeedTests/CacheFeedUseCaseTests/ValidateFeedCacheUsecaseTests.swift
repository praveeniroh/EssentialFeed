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

    func test_validate_deleteCacheOnSevenDaysOldCache() {
        let fixedCurrentData = Date()
        let (sut,store) = makeSUT(fixedCurrentData: {
            fixedCurrentData
        }())
        let feed = uniqueImageFeed()
        let sevenDaysTimeStap = fixedCurrentData.adding(days: -7)

        sut.validateCache()
        store.completeRetrival(with: feed.local, timeStamp: sevenDaysTimeStap)

        XCTAssertEqual(store.receivedMessages, [.retrive, .deleteCachedFeed])
    }

    func test_validate_deleteCacheOnMoreThanSevenDaysOldCache() {
        let fixedCurrentData = Date()
        let (sut,store) = makeSUT(fixedCurrentData: {
            fixedCurrentData
        }())
        let feed = uniqueImageFeed()
        let moreThanSevenDaysTimeStap = fixedCurrentData.adding(days: -7).adding(seconds: -1)

        sut.validateCache()
        store.completeRetrival(with: feed.local, timeStamp: moreThanSevenDaysTimeStap)

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
}
