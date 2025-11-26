//
//  XCTest+FailableRetrieveFeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Praveenraj T on 26/11/25.
//

import Foundation
import XCTest
import EssentialFeed

extension FailableRetrieveFeedStoreSpecs where Self: XCTestCase {
    func assertThatRetriveDeliversFailureOnRetivalError(_ sut: any FeedStore) {
        expect(sut, toRetrive: .failure(anyNSError()))
    }

    func assertThatRetriveHasNoSideEffectOnFailure(_ sut: any FeedStore) {
        expect(sut, toRetriveTwice: .failure(anyNSError()))
    }
}
