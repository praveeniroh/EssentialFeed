//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Praveenraj T on 25/11/25.
//

import Foundation
import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {
    @discardableResult
    func insert(_ cache: (feed: [LocalFeedImage], timeStamp: Date), to sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) -> Error? {
        let expectation = expectation(description: "Wait for Insertion to complete")
        var insertionError: Error?
        sut.insert(cache.feed, timestamp: cache.timeStamp){ error in
            insertionError = error
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        return insertionError
    }

    func expect(_ sut: FeedStore, toRetriveTwice expectedResult: RetrieveCachedFeedResult, file: StaticString = #filePath, line: UInt = #line ) {
        expect(sut, toRetrive: expectedResult)
        expect(sut, toRetrive: expectedResult)
    }

    func expect(_ sut: FeedStore, toRetrive expectedResult: RetrieveCachedFeedResult, file: StaticString = #filePath, line: UInt = #line ) {
        let expectation = expectation(description: "Wait for retrival to complete")
        sut.retrive { retrivedResult in
            switch (expectedResult, retrivedResult) {
            case (.empty, .empty), (.failure, .failure):
                break //pass
            case let (.found(expectedFeed, expectedTimeStamp), .found(retrivedFeed, retrivedTimeStamp)):
                XCTAssertEqual(expectedFeed, retrivedFeed, file: file, line: line)
                XCTAssertEqual(expectedTimeStamp, retrivedTimeStamp, file: file, line: line)
            default:
                XCTFail("Expected \(expectedResult) but got \(retrivedResult)", file: (file), line: line)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    @discardableResult
    func deleteCache(_ sut: FeedStore) -> Error? {
        let expectation = expectation(description: "Wait for cache delete completion")
        var deletionError: Error?
        sut.deleteCachedFeed { error in
            deletionError = error
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        return deletionError
    }

    func assertThatRetrieveDeliversEmptyOnEmptyCache(on sut: any FeedStore) {
        expect(sut, toRetrive: .empty)
    }

    func assertThatRetrieveHasNoSideEffectsOnEmptyCache(on sut: any FeedStore) {
        expect(sut, toRetriveTwice: .empty)
    }

    func assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on sut: any FeedStore) {
       let localFeed = uniqueImageFeed().local
       let timeStamp = Date()

       insert((localFeed, timeStamp), to: sut)
       expect(sut, toRetrive: .found(feed: localFeed, timeStamp: timeStamp))
   }

    func assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on sut: any FeedStore) {
        let localFeed = uniqueImageFeed().local
        let timeStamp = Date()

        insert((localFeed, timeStamp), to: sut)
        expect(sut, toRetriveTwice: .found(feed: localFeed, timeStamp: timeStamp))
    }

    func assertThatInsertDeliversNoErrorOnEmptyCache(on sut: any FeedStore) {
        let insertionError = insert((uniqueImageFeed().local, Date()), to: sut)

        XCTAssertNil(insertionError, "Expected insertion to be successful")
    }

    func assertThatInsertDeliversNoErrorOnNonEmptyCache(on sut: any FeedStore) {
        insert((uniqueImageFeed().local, Date()), to: sut)
        let insertionError = insert((uniqueImageFeed().local, Date()), to: sut)

        XCTAssertNil(insertionError, "Expected insertion to be successful")
    }

    func assertThatInsertHasOverridesPreviouslyInsertedCacheValues(_ sut: any FeedStore) {
        insert((uniqueImageFeed().local, Date()), to: sut)

        let latesFeed = uniqueImageFeed().local
        let latestTimeStamp = Date()
        insert((latesFeed, latestTimeStamp), to: sut)

        expect(sut, toRetrive: .found(feed: latesFeed, timeStamp: latestTimeStamp))
    }

    func assertThatDeleteHasDeliversNoErrorOnEmptyCache(_ sut: any FeedStore) {
        let deletionError = deleteCache(sut)

        XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
    }

    func assertThatDeletehasNoSideEffectsOnEmptyCache(_ sut: any FeedStore) {
        let deletionError = deleteCache(sut)

        XCTAssertNil(deletionError, "Expected to delete with no error, got \(String(describing: deletionError)) instead.")
    }

    func assertThatDeleteDeliversNoErrorOnNonEmptyCache(_ sut: any FeedStore) {
        insert((uniqueImageFeed().local, Date()), to: sut)
        let deletionError = deleteCache(sut)

        XCTAssertNil(deletionError, "Expected to delete with no error, got \(String(describing: deletionError)) instead.")
    }

    func assertThatDeleteEmptiesPreviouslyInsertedCache(_ sut: any FeedStore) {
        let feed = uniqueImageFeed().local
        let timeStamp = Date()

        insert((feed, timeStamp), to: sut)
        deleteCache(sut)

        expect(sut, toRetrive: .empty)
    }

    func assertThatSideEffectsRunSerially(_ sut: any FeedStore) {
        var completedExpectationOrder = [XCTestExpectation]()
        let op1 = expectation(description: "Operation 1")
        sut.insert(uniqueImageFeed().local, timestamp: Date()) { _ in
            completedExpectationOrder.append(op1)
            op1.fulfill()
        }

        let op2 = expectation(description: "Operation 2")
        sut.deleteCachedFeed { _ in
            completedExpectationOrder.append(op2)
            op2.fulfill()
        }

        let op3 = expectation(description: "Operation 3")
        sut.insert([], timestamp: Date()) { _ in
            completedExpectationOrder.append(op3)
            op3.fulfill()
        }
        waitForExpectations(timeout: 5.0)
        XCTAssertEqual(completedExpectationOrder, [op1,op2,op3], "Expected to run side-effects serially but got a different order.")
    }

}
