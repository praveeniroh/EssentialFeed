//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Praveenraj T on 16/10/25.
//

import XCTest

class FeedStore {
    var deleteCachedFeedCallCount = 0
}
class LocalFeedLoader {
    init(store: FeedStore) {
    }
}

final class CacheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotDeleteCacheUponDeletion() {
        let store = FeedStore()
        let _ = LocalFeedLoader(store: store)

        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }
}
