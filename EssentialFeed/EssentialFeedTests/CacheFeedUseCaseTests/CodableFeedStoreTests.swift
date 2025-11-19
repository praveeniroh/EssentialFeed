//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Praveenraj T on 19/11/25.
//

import XCTest
import EssentialFeed

class CodableFeedStore{
    func retrive(completion: @escaping FeedStore.RetrivalCompletion) {
        completion(.empty)
    }
}

class CodableFeedStoreTests: XCTestCase {

    func test_retrive_deliversEmptyOnEmptyCache()  {
        let sut = CodableFeedStore()
        let expectation = expectation(description: "Wait for retrival to complete")
        sut.retrive { result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("Expected empty but got \(result)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_retrive_hasNoSideEffectOnEmptyCache()  {
        let sut = CodableFeedStore()
        let expectation = expectation(description: "Wait for retrival to complete")
        sut.retrive { firstResult in
            sut.retrive { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                default:
                    XCTFail("Expected Retriving twice empty cache would result empty but got \(firstResult) and \(secondResult)")
                }
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

}
