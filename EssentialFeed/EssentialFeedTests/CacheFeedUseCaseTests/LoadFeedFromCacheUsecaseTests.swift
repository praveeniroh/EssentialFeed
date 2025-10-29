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

    //MARK: - Helpers
    private func makeSUT(timeStamp: @autoclosure @escaping () -> Date = Date.init(), file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: timeStamp())
        trackForMemoryLead(sut, file: file, line: line)
        trackForMemoryLead(store, file: file, line: line)
        return (sut, store)
    }

    private class FeedStoreSpy: FeedStore {
        typealias DeletionCompletion = (Error?) -> Void
        typealias InsertionCompletion = (Error?) -> Void

        var deletionCompletion = [DeletionCompletion]()
        var insertionCompletion = [InsertionCompletion]()

        enum ReceivedMessage: Equatable {
            case deleteCachedFeed
            case insert(feedItems: [LocalFeedImage], timestamp: Date)
        }

        private(set) var receivedMessages: [ReceivedMessage] = []
        func deleteCachedFeed(completion: @escaping DeletionCompletion) {
            receivedMessages.append(.deleteCachedFeed)
            deletionCompletion.append(completion)
        }

        func completeDeletion(with error: Error?, at index: Int = 0) {
            deletionCompletion[index](error)
        }

        func completeDeletionSuccessfully(at index: Int = 0) {
            deletionCompletion[index](nil)
        }

        func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
            insertionCompletion.append(completion)
            receivedMessages.append(.insert(feedItems: feed, timestamp: timestamp))
        }

        func completeInsertion(with error: Error?, at index: Int = 0) {
            insertionCompletion[index](error)
        }

        func completeInsertionSuccessfully(at index: Int = 0) {
            insertionCompletion[index](nil)
        }
    }

}
