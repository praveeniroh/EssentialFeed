//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Praveenraj T on 16/10/25.
//

import XCTest
import EssentialFeed


final class CacheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotDeleteCacheUponDeletion() {
        let (_,store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        let feedItems = [uniqueItems(), uniqueItems()]
        sut.save(feedItems){_  in}

        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let feedItems = [uniqueItems(), uniqueItems()]
        let deletionError = anyNSError()
        sut.save(feedItems){_  in}
        store.completeDeletion(with: deletionError)

        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }

    func test_save_requestNewCacheInsertionWithTimeStampOnSuccessfulDeletion() {
        let timeStamp = Date()
        let (sut, store) = makeSUT(timeStamp: timeStamp)
        let feedItems = [uniqueItems(), uniqueItems()]
        let localFeedItems = feedItems.map { LocalFeedItem(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.imageURL)}
        sut.save(feedItems){_  in}
        store.completeDeletionSuccessfully()
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(feedItems: localFeedItems, timestamp: timeStamp)])
    }

    func test_save_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        expect(sut: sut, toCompleteWithError: deletionError) {
            store.completeDeletion(with: deletionError)
        }
    }

    func test_save_failsOnInsertionError() {
        let (sut, store) = makeSUT()
        let insertionError = anyNSError()
        expect(sut: sut, toCompleteWithError: insertionError) {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        }
    }

    func test_save_succeedsOnSuccessfulCacheInsertion() {
        let (sut, store) = makeSUT()
        expect(sut: sut, toCompleteWithError: nil) {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        }
    }

    func test_save_doesNotDeliverDeletionErrorAfterSUTHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init())

        var capturedResult = [LocalFeedLoader.SaveResult]()
        sut?.save([uniqueItems()], completion: { capturedError in
            capturedResult.append(capturedError)
        })
        sut = nil
        store.completeDeletion(with: anyNSError())

        XCTAssertTrue(capturedResult.isEmpty)
    }

    func test_save_doesNotDeliverInsertionErrorAfterSUTHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init())

        var capturedResult = [LocalFeedLoader.SaveResult]()
        sut?.save([uniqueItems()], completion: { capturedError in
            capturedResult.append(capturedError)
        })
        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: anyNSError())

        XCTAssertTrue(capturedResult.isEmpty)
    }

    //MARK: - Helpers
    private func makeSUT(timeStamp: @autoclosure @escaping () -> Date = Date.init(), file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: timeStamp())
        trackForMemoryLead(sut, file: file, line: line)
        trackForMemoryLead(store, file: file, line: line)
        return (sut, store)
    }

    private func expect(sut: LocalFeedLoader, toCompleteWithError expectedError: NSError?, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        var capturedError: LocalFeedLoader.SaveResult?
        let exp = expectation(description: "Wait for save completion")

        sut.save([uniqueItems(), uniqueItems()]) { error in
            capturedError = error
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(expectedError, capturedError as? NSError)
    }

    private func uniqueItems() -> FeedItem {
        FeedItem(id: UUID(), description: "Any", location: "Any", imageURL: anyURL())
    }

    private func anyURL() -> URL {
        return URL(string: "https://some-url.com")!
    }

    private func anyNSError() -> NSError {
        NSError(domain: "Any Error", code: 0)
    }

    private class FeedStoreSpy: FeedStore {
        typealias DeletionCompletion = (Error?) -> Void
        typealias InsertionCompletion = (Error?) -> Void

        var deletionCompletion = [DeletionCompletion]()
        var insertionCompletion = [InsertionCompletion]()

        enum ReceivedMessage: Equatable {
            case deleteCachedFeed
            case insert(feedItems: [LocalFeedItem], timestamp: Date)
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

        func insert(_ items: [LocalFeedItem], timestamp: Date, completion: @escaping InsertionCompletion) {
            insertionCompletion.append(completion)
            receivedMessages.append(.insert(feedItems: items, timestamp: timestamp))
        }

        func completeInsertion(with error: Error?, at index: Int = 0) {
            insertionCompletion[index](error)
        }

        func completeInsertionSuccessfully(at index: Int = 0) {
            insertionCompletion[index](nil)
        }
    }
}
