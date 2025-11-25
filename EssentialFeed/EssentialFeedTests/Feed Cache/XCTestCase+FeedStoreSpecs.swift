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
}
