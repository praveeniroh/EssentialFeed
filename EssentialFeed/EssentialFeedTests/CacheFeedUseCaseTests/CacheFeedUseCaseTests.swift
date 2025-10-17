//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Praveenraj T on 16/10/25.
//

import XCTest
import EssentialFeed

class FeedStore {
    var deleteCachedFeedCallCount = 0
    var insertionCallCount = 0
    
    func deleteCachedFeed() {
        deleteCachedFeedCallCount += 1
    }

    func completeDeletion(with error: Error?) {

    }
}
class LocalFeedLoader {
    private let store: FeedStore
    init(store: FeedStore) {
        self.store = store
    }

    func save(_ feedItems: [FeedItem]) {
        store.deleteCachedFeed()
    }
}

final class CacheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotDeleteCacheUponDeletion() {
        let (_,store) = makeSUT()

        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }

    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        let feedItems = [uniqueItems(), uniqueItems()]
        sut.save(feedItems)

        XCTAssertEqual(store.deleteCachedFeedCallCount, 1)
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let feedItems = [uniqueItems(), uniqueItems()]
        let deletionError = anyNSError()
        sut.save(feedItems)
        store.completeDeletion(with: deletionError)

        XCTAssertEqual(store.insertionCallCount, 0)
    }

    //MARK: - Helpers
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        trackForMemoryLead(sut, file: file, line: line)
        trackForMemoryLead(store, file: file, line: line)
        return (sut, store)
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
}
