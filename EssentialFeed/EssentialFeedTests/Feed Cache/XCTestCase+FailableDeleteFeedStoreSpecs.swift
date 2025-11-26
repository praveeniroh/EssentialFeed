//
//  XCTestCase+FailableDeleteFeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Praveenraj T on 26/11/25.
//

import Foundation
import EssentialFeed
import XCTest

extension FailableDeleteFeedStoreSpecs where Self: XCTestCase {
    func assetThatDeleteDeliversErrorOnDeltionError(_ deletionError: (any Error)?, _ sut: any FeedStore) {
        XCTAssertNotNil(deletionError)

        expect(sut, toRetrive: .empty)
    }

    func assertDeleteHasNoSideEffectsOnDeletionError(_ sut: any FeedStore) {
        deleteCache(sut)

        expect(sut, toRetrive: .empty)
    }
}
