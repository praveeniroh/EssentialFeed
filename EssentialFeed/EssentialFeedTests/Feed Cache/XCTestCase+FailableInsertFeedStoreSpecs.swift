//
//  XCTestCase+FailableInsertFeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Praveenraj T on 26/11/25.
//

import Foundation
import EssentialFeed
import XCTest

extension FailableInsertFeedStoreSpecs where Self: XCTestCase {
    func assertThatInsertDeliversErrorOnInsertionError(_ localFeed: [LocalFeedImage], _ timeStamp: Date, _ sut: any FeedStore) {
        let insertionError = insert((localFeed, timeStamp), to: sut)

        XCTAssertNotNil(insertionError)
    }

    func assertInsertHasNoSideEffectsOnInsertionError(_ sut: any FeedStore) {
        insert((uniqueImageFeed().local, Date()), to: sut)

        expect(sut, toRetrive: .empty)
    }
}
